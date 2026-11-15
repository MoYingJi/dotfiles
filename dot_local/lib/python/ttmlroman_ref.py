"""ttmlroman 的参考歌词解析及保守对齐；仅使用 Python 标准库。

ESLRC 的 <mm:ss.xxx> 表示其后文本的起点，下一个标签表示终点。
不使用词典猜汉字读音，不按字符数均分音节或时间。
"""
from __future__ import annotations

from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path
import re
import unicodedata


TIME = r"\d+:\d{2}(?:[.:]\d{1,3})?"
LINE_TIME = re.compile(r"\[(" + TIME + r")\]")
WORD_TIME = re.compile(r"<(" + TIME + r")>")
META = re.compile(r"^\[([A-Za-z][\w-]*):(.*?)\]$")


def milliseconds(value):
    minute, rest = value.split(":", 1)
    parts = re.split(r"[.:]", rest)
    second = int(parts[0])
    if second >= 60:
        raise ValueError(f"无效的 LRC 时间: {value}")
    fraction = int(parts[1].ljust(3, "0")) if len(parts) == 2 else 0
    return int(minute) * 60000 + second * 1000 + fraction


def folded(text):
    text = unicodedata.normalize("NFKC", text)
    return "".join(chr(ord(c) - 0x60) if "\u30a1" <= c <= "\u30f6" else c
                   for c in text).lower()


def key(text):
    # 标点、空格不参与跨文件的原文匹配；字母、数字、日文保留。
    return "".join(c for c in folded(text) if c.isalnum() or c == "ー")


def compact(text):
    text = unicodedata.normalize("NFC", unicodedata.normalize("NFKC", text)).lower().replace("’", "'")
    return "".join(c for c in text if c.isalnum() or c == "'"
                   or unicodedata.category(c).startswith("M"))


def roman_compact(text):
    # 逐音节导出中的独立 n 本身提供了音节边界，不能把 shi n yo 读成 shi nyo。
    text = unicodedata.normalize("NFKC", text).lower().replace("’", "'")
    return compact(re.sub(r"(?<![a-z])n(?=\s+[aeiouy])", "n'", text))


def kanji(char):
    return ("\u3400" <= char <= "\u9fff" or "\U00020000" <= char <= "\U000323af"
            or char in "々〆ヶ")


@dataclass
class Row:
    text: str
    location: str
    start: int | None
    times: list[tuple[int, int, int, int]] = field(default_factory=list)


@dataclass
class Entry:
    original: Row
    roman: Row | None
    alignment: object = None


def parse(path, order, warn):
    """以时间组或明确行序分组，不把未知行序当作固定三行循环。"""
    path = Path(path).expanduser()
    rows = []
    offset = 0
    for number, raw in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), 1):
        raw = raw.strip()
        if not raw:
            continue
        meta = META.fullmatch(raw)
        if meta:
            if meta[1].lower() == "offset":
                offset = int(meta[2])
            continue
        location = f"{path.name}:{number}"
        stamps = []
        while match := LINE_TIME.match(raw):
            stamps.append(milliseconds(match[1]))
            raw = raw[match.end():]
        tags = list(WORD_TIME.finditer(raw))
        text = WORD_TIME.sub("", raw)
        times = []
        if tags:
            # 删除标签后的位置，以规范化原文的字符索引表示。
            prefix = raw[:tags[0].start()]
            position = len(key(prefix))
            for index, tag in enumerate(tags):
                stop = tags[index + 1].start() if index + 1 < len(tags) else len(raw)
                fragment = raw[tag.end():stop]
                length = len(key(fragment))
                start = milliseconds(tag[1])
                end = milliseconds(tags[index + 1][1]) if index + 1 < len(tags) else None
                if length:
                    if end is None or end <= start:
                        warn(f"{location}: ESLRC 片段 {fragment!r} 缺少终点或时间倒退，忽略该段时间")
                    else:
                        times.append((position, position + length, start, end))
                position += length
            invalid = set()
            for i, left in enumerate(times):
                for j in range(i + 1, len(times)):
                    right = times[j]
                    if left[3] > right[2]:
                        invalid.update((i, j))
            if invalid:
                warn(f"{location}: {len(invalid)} 个 ESLRC 片段重叠或顺序倒退，忽略这些片段时间")
                times = [v for i, v in enumerate(times) if i not in invalid]
        if text.strip():
            # 多个行标签表示重复演唱；逐字标签只有一套，不能移植到其他起点。
            for index, stamp in enumerate(stamps or [None]):
                rows.append(Row(text, location, stamp, list(times) if index == 0 else []))
    # LRC offset 的正值表示歌词提前，绝对时间需减去 offset。
    for row in rows:
        if row.start is not None:
            row.start -= offset
        row.times = [(a, b, s - offset, e - offset) for a, b, s, e in row.times
                     if s - offset >= 0]
    if not rows:
        raise ValueError(f"{path}: 没有可读取的歌词")
    timed = all(row.start is not None for row in rows)
    groups = []
    if timed:
        rows.sort(key=lambda row: row.start)
        for row in rows:
            if groups and groups[-1][0].start == row.start:
                groups[-1].append(row)
            else:
                groups.append([row])
    elif order != "auto":
        groups = [rows[i:i + len(order)] for i in range(0, len(rows), len(order))]
    else:
        # 自动识别原文中的假名及其邻近音译；全汉字行也可由同一文件已知行序识别。
        japanese = [i for i, row in enumerate(rows)
                    if any("\u3040" <= c <= "\u30ff" for c in row.text)]
        if not japanese:
            raise ValueError(f"{path}: 无法自动识别原文，请指定 --reference-order")
        distances = [b - a for a, b in zip(japanese, japanese[1:]) if 1 <= b - a <= 3]
        width = max(set(distances), key=lambda n: (distances.count(n), n)) if distances else len(rows)
        if width > 3 or width < 1:
            raise ValueError(f"{path}: 无法识别行序，请指定 --reference-order")
        origin_index = japanese[0] % width
        # 识别第一组。音译必须主要为拉丁字母，避免误用翻译。
        first = rows[:width]
        roman_indices = [i for i, row in enumerate(first) if i != origin_index
                         and any(c.isascii() and c.isalpha() for c in row.text)
                         and not any(kanji(c) or "\u3040" <= c <= "\u30ff" for c in row.text)]
        roman_index = roman_indices[0] if len(roman_indices) == 1 else None
        labels = ["译"] * width
        labels[origin_index] = "主"
        if roman_index is not None:
            labels[roman_index] = "音"
        order = "".join(labels)
        groups = [rows[i:i + width] for i in range(0, len(rows), width)]
    entries = []
    inferred_order = order
    for group in groups:
        actual = order
        if actual == "auto":
            originals = [i for i, row in enumerate(group)
                         if any("\u3040" <= c <= "\u30ff" for c in row.text)]
            if len(originals) == 1:
                oi = originals[0]
                romans = [i for i, row in enumerate(group) if i != oi
                          and any(c.isascii() and c.isalpha() for c in row.text)
                          and not any(kanji(c) for c in row.text)]
                labels = ["译"] * len(group)
                labels[oi] = "主"
                if len(romans) == 1:
                    labels[romans[0]] = "音"
                actual = "".join(labels)
                inferred_order = actual
            elif inferred_order != "auto" and len(inferred_order) == len(group):
                actual = inferred_order
            else:
                warn(f"{group[0].location}: 无法识别原文/音译行，跳过该时间组")
                continue
        if len(group) != len(actual):
            warn(f"{group[0].location}: 歌词行数与行序 {actual} 不一致，跳过该组")
            continue
        original = group[actual.index("主")]
        roman = group[actual.index("音")] if "音" in actual else None
        if roman and any(kanji(c) or "\u3040" <= c <= "\u30ff" for c in roman.text):
            warn(f"{roman.location}: 指定的音译行含汉字/假名，可能行序不符；忽略该组")
            continue
        entries.append(Entry(original, roman))
    return entries


def variants(kana, value):
    result = {value}
    aliases = {
        "shi": ("si",), "chi": ("ti",), "tsu": ("tu",), "fu": ("hu",),
        "ji": ("zi", "di"), "sha": ("sya",), "shu": ("syu",), "sho": ("syo",),
        "cha": ("tya", "cya"), "chu": ("tyu", "cyu"), "cho": ("tyo", "cyo"),
        "ja": ("zya", "jya"), "ju": ("zyu", "jyu"), "jo": ("zyo", "jyo"),
    }
    result.update(aliases.get(value, ()))
    if kana == "を":
        result.add("wo")
    elif kana == "づ":
        result.add("du")
    elif kana in ("ぢゃ", "ぢゅ", "ぢょ"):
        result.add("dy" + value[-1])
    return result


def format_reading(text, single, combo):
    """按规范建议分隔假名读音；ん接前音，促音接后音，拗音不拆。

    这里只接受已经完成消歧的规范拼写，不再推断别名或长音。
    返回 None 表示连规范拼写的分隔也无法唯一确定。
    """
    syllables = set(single.values()) | set(combo.values())
    syllables.discard("n")

    def prepend(value, tail):
        if not tail:
            return value
        # 只把独立 n 接在前音之后，不能把 na/ni/nya 等误当作撥音。
        first = tail.split(" ", 1)[0]
        join = first in ("n", "n'")
        return value + ("" if join else " ") + tail

    @lru_cache(maxsize=None)
    def walk(pos):
        if pos == len(text):
            return frozenset(("",))
        values = set()
        for value in syllables:
            if text.startswith(value, pos):
                values.update(prepend(value, tail) for tail in walk(pos + len(value)))
        if text.startswith("n'", pos):
            values.update(prepend("n'", tail) for tail in walk(pos + 2))
        elif text.startswith("n", pos) and text[pos + 1:pos + 2] not in ("a", "i", "u", "e", "o", "y"):
            values.update(prepend("n", tail) for tail in walk(pos + 1))
        if pos + 1 < len(text):
            consonant = text[pos]
            if (consonant in "kgsztdhfbpjcv"
                    and (text[pos + 1] == consonant or text[pos:pos + 3] == "tch")):
                values.update(consonant + tail for tail in walk(pos + 1))
        if len(values) > 1:
            return frozenset(("\0",))
        return frozenset(values)

    values = walk(0)
    if len(values) == 1:
        value = next(iter(values))
        if "\0" not in value:
            return value
    return None


class _ReadingPath:
    """原文与音译的有向无环对齐图；保留所有可行边，避免任取一种切分。"""
    def __init__(self, entry, single, combo, warn):
        self.entry = entry
        self.original = key(entry.original.text)
        self.original_chars = [c for c in unicodedata.normalize("NFKC", entry.original.text)
                               if c.isalnum() or c == "ー"]
        self.roman = compact(entry.roman.text)
        self.warn = warn
        self.edges = {}
        self.valid = False
        self.reported = set()
        units = []
        index = 0
        while index < len(self.original):
            start = index
            pair = self.original[index:index + 2]
            if pair in combo:
                index += 2
            elif self.original[index].isascii() and self.original[index].isalnum():
                index += 1
                while index < len(self.original) and self.original[index].isascii() and self.original[index].isalnum():
                    index += 1
            else:
                index += 1
            units.append((start, index, self.original[start:index]))
        self.units = units
        # 用于汉字的音节词表。保留少数有多种有效解释的拼写，不能擅自选取。
        syllables = {}
        for kana, value in {**single, **combo}.items():
            if kana in "ぁぃぅぇぉゃゅょゎゕゖ":
                continue
            for spelling in variants(kana, value):
                syllables.setdefault(spelling, set()).add(value)
        self.syllables = syllables
        self.normalized = lru_cache(maxsize=None)(self._normalize)

        @lru_cache(maxsize=None)
        def build(ui, ri):
            if ui == len(units):
                return ri == len(self.roman)
            a, b, kana = units[ui]
            options = []
            if all(kanji(c) for c in kana):
                # 一字可有多个音节；相邻汉字的所有切分都参与一致性检查。
                for end in range(ri + 1, len(self.roman) + 1):
                    for value in self.normalized(self.roman[ri:end]):
                        options.append((end, value, (value,), self.roman[ri:end] != value))
            elif kana == "っ":
                if ri < len(self.roman) and self.roman[ri] in "kgsztdhfbpjcv":
                    c = self.roman[ri]
                    # 下一单元必须能消耗相同辅音；ch 的促音采用 t。
                    if (self.roman[ri + 1:ri + 2] == c
                            or (c == "t" and self.roman[ri + 1:ri + 3] == "ch")):
                        value = "t" if c == "c" and self.roman[ri + 1:ri + 3] == "ch" else c
                        options.append((ri + 1, value, (value,), value != c))
            elif kana == "ー":
                previous = self.roman[ri - 1:ri] if ri else ""
                if previous in "aeiou" and previous:
                    if self.roman[ri:ri + 1] == previous:
                        options.append((ri + 1, previous, (previous,), False))
            elif kana == "ん":
                for spelling in ("n'", "n", "m"):
                    if spelling == "m" and self.roman[ri + 1:ri + 2] not in ("b", "p", "m"):
                        continue
                    if self.roman.startswith(spelling, ri):
                        end = ri + len(spelling)
                        value = "n'" if self.roman[end:end + 1] in ("a", "i", "u", "e", "o", "y") else "n"
                        options.append((end, value, (value,), spelling != value))
            elif kana in single or kana in combo:
                canonical = combo.get(kana, single.get(kana))
                values = [canonical]
                if kana == "は" and self.original_chars[a] == "は":
                    values.append("wa")
                elif kana == "へ" and self.original_chars[a] == "へ":
                    values.append("e")
                for value in values:
                    spellings = variants(kana, value)
                    # 导出器有时把小假名按大假名转写：te i → ti, fu a → fa。
                    if len(kana) == 2:
                        spellings.add(single[kana[0]] + single[kana[1]])
                    for spelling in spellings:
                        if self.roman.startswith(spelling, ri):
                            pieces = (value[:-1], value[-1]) if len(kana) == 2 else (value,)
                            options.append((ri + len(spelling), value, pieces, spelling != value))
            elif kana.isascii() and kana.isalnum():
                spelling = compact(kana)
                if self.roman.startswith(spelling, ri):
                    options.append((ri + len(spelling), "", tuple("" for _ in kana), False))
                # 原文中的英语通常无需另列罗马音，允许音译行省去它。
                options.append((ri, "", tuple("" for _ in kana), False))
            live = []
            for end, value, pieces, changed in options:
                if build(ui + 1, end):
                    live.append((end, value, pieces, changed))
            if live:
                self.edges[ui, ri] = live
            return bool(live)

        self.valid = build(0, 0)
        if not self.valid:
            warn(f"{entry.roman.location}: 音译无法与原文完整对齐或含无法规范化的拼写；"
                 "该行参考读音留空，仍保留独立可识别的假名规则")

    def _normalize(self, text):
        """所有可接受的音节解析；多种规范拼写时不选取其中之一。"""
        @lru_cache(maxsize=None)
        def walk(pos):
            if pos == len(text):
                return frozenset(("",))
            values = set()
            for spelling, canonicals in self.syllables.items():
                if spelling == "n" and text[pos + 1:pos + 2] in ("a", "i", "u", "e", "o", "y"):
                    continue
                if text.startswith(spelling, pos):
                    for tail in walk(pos + len(spelling)):
                        for canonical in canonicals:
                            value = canonical + tail
                            values.add(value)
                            if len(values) > 64:
                                return frozenset(("\0",))
            if text[pos:pos + 1] == "n" and text[pos + 1:pos + 2] == "'":
                values.update("n'" + tail for tail in walk(pos + 2))
            if text[pos:pos + 1] == "m" and text[pos + 1:pos + 2] in ("b", "p", "m"):
                values.update("n" + tail for tail in walk(pos + 1))
            if pos + 1 < len(text):
                c = text[pos]
                if c in "kgsztdhfbpjcv" and (text[pos + 1] == c or text[pos:pos + 3] == "tch"):
                    value = "t" if c == "c" and text[pos + 1:pos + 3] == "ch" else c
                    values.update(value + tail for tail in walk(pos + 1))
            return frozenset(values)
        return walk(0)

    def get(self, start, end):
        if not self.valid:
            return None
        @lru_cache(maxsize=None)
        def collect(ui, ri):
            if ui == len(self.units):
                return frozenset(("",))
            a, b, _ = self.units[ui]
            values = set()
            for stop, value, pieces, changed in self.edges.get((ui, ri), []):
                piece = "".join(pieces[max(0, start - a):min(b - a, end - a)]) if a < end and b > start else ""
                for tail in collect(ui + 1, stop):
                    values.add(piece + tail)
                    if len(values) > 8:
                        # 超过上限视为歧义；绝不截取一个候选充当答案。
                        return frozenset(("\0",))
            return frozenset(values)
        values = collect(0, 0)
        if len(values) != 1:
            return None
        value = next(iter(values), "")
        if "\0" in value or not value:
            return None
        if (start, end) not in self.reported and any(
                changed and start <= self.units[ui][0] and self.units[ui][1] <= end
                and all(kanji(c) for c in self.units[ui][2])
                for ui, ri in getattr(self, "active_states", ())
                for _, _, _, changed in self.edges.get((ui, ri), [])):
            self.warn(f"{self.entry.roman.location}: 已将参考汉字音译规范化为 {value!r}")
            self.reported.add((start, end))
        return value

    def report_normalizations(self):
        # 只报告从根可达的有效路径中的改写。
        pending, seen = [(0, 0)], set()
        changes = set()
        while pending:
            state = pending.pop()
            if state in seen:
                continue
            seen.add(state)
            ui, ri = state
            for end, value, _, changed in self.edges.get(state, []):
                if changed and not all(kanji(c) for c in self.units[ui][2]):
                    changes.add((self.roman[ri:end], value))
                pending.append((ui + 1, end))
        self.active_states = seen
        if changes:
            details = ", ".join(f"{a}→{b}" for a, b in sorted(changes))
            self.warn(f"{self.entry.roman.location}: 音译拼写规范化（结合原文假名）: {details}")
        if self.entry.roman.text != unicodedata.normalize("NFKC", self.entry.roman.text).lower().replace("’", "'"):
            self.warn(f"{self.entry.roman.location}: 已规范化音译的大小写、全角字符或撇号")


class Reading:
    """长音附标也保留全部可能拼写，由明确的原文假名消歧。"""
    def __init__(self, entry, single, combo, warn):
        self.entry, self.warn = entry, warn
        self.messages = set()
        alternatives = {
            "ā": ("aa",), "â": ("aa",), "ī": ("ii",), "î": ("ii",),
            "ū": ("uu",), "û": ("uu",), "ē": ("ee", "ei"), "ê": ("ee", "ei"),
            "ō": ("oo", "ou"), "ô": ("oo", "ou"),
        }
        original = roman_compact(entry.roman.text)
        spellings = {""}
        for char in original:
            spellings = {prefix + suffix for prefix in spellings
                         for suffix in alternatives.get(char, (char,))}
            if len(spellings) > 64:
                self.paths, self.valid = [], False
                warn(f"{entry.roman.location}: 长音拼写候选过多，无法唯一推测，该行参考读音留空")
                return
        self.paths = []
        for spelling in sorted(spellings):
            row = Row(spelling, entry.roman.location, entry.roman.start)
            path = _ReadingPath(Entry(entry.original, row), single, combo, lambda message: None)
            if path.valid:
                path.warn = self._warn_once
                self.paths.append(path)
        self.valid = bool(self.paths)
        if not self.valid:
            warn(f"{entry.roman.location}: 音译无法与原文完整对齐或含无法规范化的拼写；"
                 "该行参考读音留空，仍保留独立可识别的假名规则")

    def _warn_once(self, message):
        if message not in self.messages:
            self.messages.add(message)
            self.warn(message)

    def get(self, start, end):
        readings = [path.get(start, end) for path in self.paths]
        if readings and all(readings) and len(set(readings)) == 1:
            value = readings[0]
            if any(c in "āâīîūûēêōô" for c in compact(self.entry.roman.text)):
                self._warn_once(f"{self.entry.roman.location}: 结合原文/词边界展开长音附标，明确读音为 {value!r}")
            return value
        return None

    def report_normalizations(self):
        for path in self.paths:
            path.report_normalizations()
        raw = self.entry.roman.text
        if roman_compact(raw) != compact(raw):
            self._warn_once(f"{self.entry.roman.location}: 独立 n 在元音/y 前规范写为 n'")
        if raw != unicodedata.normalize("NFC", unicodedata.normalize("NFKC", raw)).lower().replace("’", "'"):
            self._warn_once(f"{self.entry.roman.location}: 已规范化音译的大小写、全角字符或撇号")


class References:
    def __init__(self, paths, order, single, combo, warn):
        self.sources = [parse(path, order, warn) for path in paths]
        self.single, self.combo, self.warn = single, combo, warn
        self.matches = {}

    def bind(self, scopes):
        """最大化有序匹配的字符数；只采纳所有最优对齐都包含的唯一位置。

        个别行被编辑器调换顺序时可以跳过，不能让一次贪心跳转影响整个副歌。
        重复副歌缺失/多出一次时，通过最优路径计数保留其真实的匹配歧义。
        """
        for entries in self.sources:
            stream, positions = "", []
            for entry in entries:
                text = key(entry.original.text)
                positions.extend((entry, i) for i in range(len(text)))
                stream += text
            candidates = []
            for order, (scope, text) in enumerate(scopes):
                needle = key(text)
                cursor = 0
                while needle and (pos := stream.find(needle, cursor)) >= 0:
                    candidates.append((order, scope, pos, pos + len(needle)))
                    cursor = pos + 1
            forward, backward = [], [None] * len(candidates)
            for i, (order, scope, start, end) in enumerate(candidates):
                best, count = 0, 1
                for j in range(i):
                    if candidates[j][0] < order and candidates[j][3] <= start:
                        score, ways = forward[j]
                        if score > best:
                            best, count = score, ways
                        elif score == best:
                            count += ways
                forward.append((best + end - start, count))
            for i in reversed(range(len(candidates))):
                order, scope, start, end = candidates[i]
                best, count = 0, 1
                for j in range(i + 1, len(candidates)):
                    if candidates[j][0] > order and candidates[j][2] >= end:
                        score, ways = backward[j]
                        if score > best:
                            best, count = score, ways
                        elif score == best:
                            count += ways
                backward[i] = best + end - start, count
            maximum = max((score for score, _ in forward), default=0)
            total = sum(count for score, count in forward if score == maximum)
            live = {}
            for i, (_, scope, start, end) in enumerate(candidates):
                left, lc = forward[i]
                right, rc = backward[i]
                if left + right - (end - start) == maximum:
                    live.setdefault(scope, []).append((start, end, lc * rc))
            for scope, paths in live.items():
                if len(paths) == 1 and paths[0][2] == total:
                    start, end, _ = paths[0]
                    self.matches.setdefault(scope, []).append(positions[start:end])

    def lookup(self, scope, spans):
        """spans 是 (owner, 规范化字符起点, 终点)，返回读音及精确边界的时间候选。"""
        result, timings = {}, {}
        matched = self.matches.get(scope, [])
        for owner, start, end in spans:
            readings, intervals = [], []
            for positions in matched:
                segment = positions[start:end]
                if not segment:
                    continue
                entry, a = segment[0]
                last, b = segment[-1]
                if entry is not last or b - a + 1 != len(segment):
                    continue
                if entry.roman is not None:
                    if entry.alignment is None:
                        entry.alignment = Reading(entry, self.single, self.combo, self.warn)
                        if entry.alignment.valid:
                            entry.alignment.report_normalizations()
                    value = entry.alignment.get(a, b + 1)
                    if value:
                        readings.append(value)
                tokens = [(x, y, s, e) for x, y, s, e in entry.original.times
                          if a <= x and y <= b + 1]
                if tokens and tokens[0][0] == a and tokens[-1][1] == b + 1:
                    if all(left[1] == right[0] and left[3] <= right[2]
                           for left, right in zip(tokens, tokens[1:])):
                        intervals.append((tokens[0][2], tokens[-1][3]))
            if readings and len(set(readings)) == 1:
                result[owner] = readings[0]
            elif readings:
                self.warn("多个参考文件对同一正文词给出冲突读音，留空")
                result[owner] = None
            if intervals and len(set(intervals)) == 1:
                timings[owner] = intervals[0]
            elif intervals:
                self.warn("多个参考文件对同一正文词给出冲突时间，保留原时间")
        return result, timings
