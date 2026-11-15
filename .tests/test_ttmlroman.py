"""运行：python3 -m unittest discover -s .tests -p 'test_ttmlroman.py'"""
from importlib.machinery import SourceFileLoader
from importlib.util import module_from_spec, spec_from_loader
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from xml.dom import minidom
from xml.sax.saxutils import escape

sys.dont_write_bytecode = True

SCRIPT = Path(__file__).resolve().parents[1] / "dot_local/bin/exact_chezmoi/executable_ttmlroman"
LOADER = SourceFileLoader("ttmlroman", str(SCRIPT))
SPEC = spec_from_loader(LOADER.name, LOADER)
roman = module_from_spec(SPEC)
sys.modules[SPEC.name] = roman
LOADER.exec_module(roman)


def word(text, begin="1.000", end="1.250"):
    return f'<span begin="{begin}" end="{end}">{escape(text)}</span>'


def document(content, head="", key=' itunes:key="L1"'):
    return (f'<tt xmlns="{roman.TT}" xmlns:ttm="{roman.TTM}" '
            f'xmlns:tts="{roman.TTS}" xmlns:itunes="{roman.APPLE}">'
            f'<head><metadata>{head}</metadata></head><body><div>'
            f'<p begin="1" end="4"{key}>{content}</p>'
            f'</div></body></tt>').encode()


def track(text, lang="ja-Latn"):
    return (f'<iTunesMetadata xmlns="{roman.APPLE}"><transliterations>'
            f'<transliteration xml:lang="{lang}"><text for="L1">{text}</text>'
            '</transliteration></transliterations></iTunesMetadata>')


def read_words(data):
    doc = minidom.parseString(data)
    tracks = [t for t in doc.getElementsByTagNameNS(roman.APPLE, "transliteration")
              if t.getAttributeNS(roman.XML, "lang") == "ja-Latn"]
    return [s.firstChild.data for t in tracks
            for s in t.getElementsByTagNameNS(roman.TT, "span") if not roman.role(s)]


class RomanizationTest(unittest.TestCase):
    def test_rules_and_cross_span_allocation(self):
        cases = [
            (["テ", "ィ", "ッ", "ク"], ["t", "i", "k", "ku"]),
            (["シ", "ャ"], ["sh", "a"]),
            (["ファンタスティック"], ["fan ta su ti kku"]),
            (["きゃっち"], ["kya tchi"]),
            (["フ", "ュ", "ー"], ["fy", "u", "u"]),
            (["ゲ", "ー", "ム"], ["ge", "e", "mu"]),
            (["し", "ん", "い"], ["shi", "n'", "i"]),
            (["ん", "や"], ["n'", "ya"]),
            (["を", "は", "へ", "ハ", "ヘ", "ぢ", "づ"], ["o", "ha", "he", "ji", "zu"]),
            (["ｼｬｯﾀｰ", "カ\u3099", "か", "\u3099"], ["sha ttaa", "ga", "ga"]),
            (["漢あ漢い字", "CM", "！"], []),  # 不用假名部分掩盖汉字读音缺漏。
            (["っ", "ー"], []),
        ]
        for source, expected in cases:
            with self.subTest(source=source):
                result, _ = roman.convert(document("".join(map(word, source))),
                                          allow_ambiguous_timing=True)
                self.assertEqual(read_words(result), expected)

    def test_spaces_unknowns_and_background_are_context_boundaries(self):
        content = (word("テ") + " " + word("ィ") + word("漢")
                   + word("ー") + '<span ttm:role="x-bg">'
                   + word("きゃ") + word("ん") + "</span>" + word("ャ"))
        result, _ = roman.convert(document(content), allow_ambiguous_timing=True)
        self.assertEqual(read_words(result), ["te", "i", "ya", "kya", "n"])
        doc = minidom.parseString(result)
        bg = [n for n in doc.getElementsByTagNameNS(roman.TT, "span")
              if roman.role(n) == "x-bg"]
        self.assertEqual(len(bg), 2)  # 正文和新增音译各一个。

    def test_original_body_metadata_and_whitespace_survive(self):
        translation = (f'<iTunesMetadata xmlns="{roman.APPLE}"><translations>'
                       '<translation xml:lang="zh-Hans"><text for="L1">译文&amp;原文</text>'
                       '</translation></translations></iTunesMetadata>')
        source = document(word("あ", "1", "2") + " " + word("い", "2", "4"), translation)
        result, stats = roman.convert(source)
        before, after = map(minidom.parseString, (source, result))
        for namespace, name in [(roman.TT, "body"), (roman.APPLE, "translations")]:
            self.assertEqual(before.getElementsByTagNameNS(namespace, name)[0].toxml(),
                             after.getElementsByTagNameNS(namespace, name)[0].toxml())
        self.assertEqual(stats, (1, 2, 0, 0))
        spans = after.getElementsByTagNameNS(roman.APPLE, "text")[-1].childNodes
        self.assertEqual([n.data for n in spans if n.nodeType == n.TEXT_NODE], [" "])
        self.assertEqual([(s.getAttribute("begin"), s.getAttribute("end"))
                          for s in spans if s.nodeType == s.ELEMENT_NODE],
                         [("1", "2"), ("2", "4")])

    def test_preserve_existing_and_replace_after_retiming(self):
        source = document(word("あ", "2", "3"), track("manual"))
        self.assertEqual(roman.convert(source)[0], source)
        updated, _ = roman.convert(source, replace=True)
        self.assertEqual(read_words(updated), ["a"])
        self.assertNotIn(b"manual", updated)
        self.assertEqual(roman.convert(updated)[0], updated)
        self.assertEqual(roman.convert(updated, replace=True)[0], updated)
        span = minidom.parseString(updated).getElementsByTagNameNS(roman.TT, "span")[0]
        self.assertEqual(span.getAttribute("begin"), "2")

    def test_inline_annotations_and_other_languages(self):
        inline = '<span ttm:role="x-roman">manual</span>'
        source = document(word("あ") + inline + '<span ttm:role="x-translation">かな</span>')
        self.assertEqual(roman.convert(source)[0], source)
        result, _ = roman.convert(source, replace=True)
        self.assertNotIn(b"manual", result)
        self.assertEqual(read_words(result), ["a"])
        source = document(word("あ"), track("other", "ja-Latn-kunrei"))
        result, _ = roman.convert(source, replace=True)
        self.assertIn(b"other", result)
        self.assertEqual(read_words(result), ["a"])

    def test_ruby_annotation_does_not_supply_a_kanji_reading(self):
        content = ('<span begin="1" end="2" tts:ruby="container">'
                   '<span tts:ruby="base">漢字</span>'
                   '<span tts:ruby="text">かんじ</span></span>' + word("かな", "2", "3"))
        result, _ = roman.convert(document(content))
        self.assertEqual(read_words(result), ["ka na"])

    def test_allocate_keys_avoids_existing_links_and_duplicates(self):
        source = document(word("あ"), track("preserve"), key="")
        result, _ = roman.convert(source)
        self.assertIn(b'for="L2"', result)
        self.assertIn(b'itunes1:key="L2"', result)
        duplicate = source.replace(b"</div>", b'<p itunes:key="L1"/><p itunes:key="L1"/></div>')
        with self.assertRaisesRegex(ValueError, "重复"):
            roman.convert(duplicate)

    def test_prefixed_namespaces_are_roundtrippable(self):
        source = document(word("きゃ")).decode()
        source = source.replace('<tt xmlns=', '<q:tt xmlns:q=').replace("</tt>", "</q:tt>")
        for tag in ["head", "metadata", "body", "div", "p", "span"]:
            source = source.replace("<" + tag, "<q:" + tag).replace("</" + tag, "</q:" + tag)
        result, _ = roman.convert(source.encode())
        self.assertEqual(read_words(result), ["kya"])

    def test_missing_word_timing_is_an_error(self):
        for content in ["かな", '<span begin="1">かな</span>']:
            with self.subTest(content=content), self.assertRaisesRegex(ValueError, "begin/end"):
                roman.convert(document(content))

    def test_draft_duplicate_timestamps_are_reported(self):
        source = document(word("漢", "0", "0") + word("かな", "0", "0"))
        with self.assertRaisesRegex(ValueError, "空音译"):
            roman.convert(source)
        _, stats = roman.convert(source, allow_ambiguous_timing=True)
        self.assertEqual(stats, (1, 1, 0, 1))

    def test_ambiguous_kana_leave_entire_word_unfilled(self):
        for kana in ["は", "へ", "こんにちは", "へや", "あっ", "ーあ"]:
            with self.subTest(kana=kana):
                source = document(word(kana) + " " + word("ハヘ", "2", "3"))
                result, _ = roman.convert(source)
                self.assertEqual(read_words(result), ["ha he"])
        result, _ = roman.convert(document(word("き") + word("ゃは")))
        self.assertEqual(read_words(result), [])

    def test_complete_zero_timed_words_and_sparse_real_timing(self):
        source = document(word("あ", "0", "0") + word("い", "0", "0"))
        result, stats = roman.convert(source)
        self.assertEqual(read_words(result), ["a", "i"])
        self.assertEqual(stats[-1], 0)
        source = document(word("あ", "0", "1") + word("漢", "1", "2") + word("い", "2", "3"))
        result, stats = roman.convert(source)
        self.assertEqual(read_words(result), ["a", "i"])
        self.assertEqual(stats[-1], 0)

    def test_timing_guard_normalizes_and_uses_actual_tolerance(self):
        for second in ["1:00", "60.001", "60.002"]:
            with self.subTest(second=second), self.assertRaisesRegex(ValueError, "2 ms"):
                roman.convert(document(word("は", "60", "61") + word("あ", second, "62")))
        roman.convert(document(word("は", "60", "61") + word("あ", "60.003", "62")))

    def test_invalid_xml_or_namespace_rejected(self):
        with self.assertRaises(ValueError):
            roman.convert(b"<tt><body/></tt>")
        with self.assertRaises(ValueError):
            roman.convert(document(word("あ")).replace(b"<tt ", b'<!DOCTYPE tt><tt '))


class SyntheticTimingTest(unittest.TestCase):
    def test_sparse_annotations_get_matching_distinct_times_and_ranges(self):
        content = "".join(word(text, "0", "0") for text in ["あ", "漢", "は", "い"])
        source = document(content).replace(b"<body>", b'<body dur="0">')
        source = source.replace(b"<div>", b'<div dur="0">')
        result, stats = roman.convert(source, synthetic_timing=True)
        self.assertEqual(read_words(result), ["a", "i"])
        self.assertEqual(stats, (1, 2, 0, 0))
        doc = minidom.parseString(result)
        body = doc.getElementsByTagNameNS(roman.TT, "body")[0]
        spans = body.getElementsByTagNameNS(roman.TT, "span")
        self.assertEqual([(s.getAttribute("begin"), s.getAttribute("end")) for s in spans],
                         [("1.000", "1.250"), ("1.250", "1.500"),
                          ("1.500", "1.750"), ("1.750", "2.000")])
        for name in ["div", "p"]:
            node = body.getElementsByTagNameNS(roman.TT, name)[0]
            self.assertEqual((node.getAttribute("begin"), node.getAttribute("end")),
                             ("1.000", "2.000"))
        self.assertEqual(body.getAttribute("begin"), "0.000")
        self.assertEqual(body.getAttribute("end"), "2.000")
        self.assertEqual(body.getAttribute("dur"), "2.000")
        self.assertEqual(body.getElementsByTagNameNS(roman.TT, "div")[0].getAttribute("dur"), "1.000")
        track = doc.getElementsByTagNameNS(roman.APPLE, "transliteration")[0]
        self.assertEqual([s.getAttribute("begin") for s in track.getElementsByTagNameNS(roman.TT, "span")],
                         ["1.000", "1.750"])

    def test_spans_can_have_no_previous_timing_but_plain_text_is_not_split(self):
        result, _ = roman.convert(document("<span>あ</span><span>漢</span><span>い</span>"),
                                  synthetic_timing=True)
        self.assertEqual(read_words(result), ["a", "i"])
        with self.assertRaisesRegex(ValueError, "begin/end"):
            roman.convert(document("かな"), synthetic_timing=True)

    def test_background_gets_independent_times_and_correct_bounds(self):
        content = (word("漢", "0", "0") + '<span ttm:role="x-bg" begin="0" end="0">'
                   + word("あ", "0", "0") + word("は", "0", "0")
                   + "</span>" + word("い", "0", "0"))
        result, _ = roman.convert(document(content), synthetic_timing=True)
        doc = minidom.parseString(result)
        body = doc.getElementsByTagNameNS(roman.TT, "body")[0]
        background = [s for s in body.getElementsByTagNameNS(roman.TT, "span")
                      if roman.role(s) == "x-bg"][0]
        self.assertEqual((background.getAttribute("begin"), background.getAttribute("end")),
                         ("1.250", "1.750"))
        track = doc.getElementsByTagNameNS(roman.APPLE, "transliteration")[0]
        timed = [s for s in track.getElementsByTagNameNS(roman.TT, "span") if s.hasAttribute("begin")]
        self.assertEqual([s.getAttribute("begin") for s in timed], ["1.750", "1.250"])

    def test_only_kanji_lines_still_get_times_and_keys(self):
        source = document("<span>漢</span>", key="")
        result, stats = roman.convert(source, synthetic_timing=True)
        self.assertEqual(stats, (0, 0, 0, 0))
        self.assertNotEqual(result, source)
        doc = minidom.parseString(result)
        line = doc.getElementsByTagNameNS(roman.TT, "p")[0]
        self.assertEqual(roman.line_key(line), "L1")
        self.assertEqual(line.getAttribute("begin"), "1.000")
        self.assertEqual(read_words(result), [])

    def test_existing_word_tracks_cannot_keep_stale_times(self):
        source = document(word("あ", "0", "0"), track(word("manual", "0", "0")))
        with self.assertRaisesRegex(ValueError, "--replace"):
            roman.convert(source, synthetic_timing=True)
        result, _ = roman.convert(source, replace=True, synthetic_timing=True)
        self.assertEqual(read_words(result), ["a"])
        self.assertNotIn(b"manual", result)
        self.assertEqual(roman.convert(result, replace=True, synthetic_timing=True)[0], result)
        other_language = document(word("あ"), track(word("other"), "ko-Latn"))
        with self.assertRaisesRegex(ValueError, "其他语言"):
            roman.convert(other_language, replace=True, synthetic_timing=True)

    def test_ruby_reading_shares_the_word_time(self):
        source = document(
            '<span tts:ruby="container"><span tts:ruby="base">かな</span>'
            '<span tts:ruby="text" begin="0" end="0">かな</span></span>'
        )
        result, _ = roman.convert(source, synthetic_timing=True)
        self.assertEqual(read_words(result), ["ka na"])
        doc = minidom.parseString(result)
        body = doc.getElementsByTagNameNS(roman.TT, "body")[0]
        reading = [s for s in body.getElementsByTagNameNS(roman.TT, "span")
                   if s.getAttributeNS(roman.TTS, "ruby") == "text"][0]
        self.assertEqual((reading.getAttribute("begin"), reading.getAttribute("end")),
                         ("1.000", "1.250"))


class CliTest(unittest.TestCase):
    def run_cli(self, *args, data=None):
        return subprocess.run([sys.executable, str(SCRIPT), *map(str, args)],
                              input=data, capture_output=True)

    def test_pipe_file_backup_and_error_leave_input_intact(self):
        source = document(word("ティ"))
        result = self.run_cli("-q", data=source)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(read_words(result.stdout), ["ti"])
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "input.ttml"
            path.write_bytes(source)
            result = self.run_cli("-i.bak", path)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(Path(str(path) + ".bak").read_bytes(), source)
            changed = path.read_bytes()
            result = self.run_cli("-i.bak", path)
            self.assertEqual(result.returncode, 1)
            self.assertEqual(path.read_bytes(), changed)
            path.write_bytes(b"<broken>")
            result = self.run_cli("-i", path)
            self.assertEqual(result.returncode, 1)
            self.assertEqual(path.read_bytes(), b"<broken>")
            result = self.run_cli(path, "-o", path)
            self.assertEqual(result.returncode, 2)
            path.write_bytes(document(word("は", "0", "0") + word("あ", "0", "0")))
            original = path.read_bytes()
            result = self.run_cli("-i", path)
            self.assertEqual(result.returncode, 1)
            self.assertEqual(path.read_bytes(), original)
        self.assertEqual(self.run_cli("-i", data=source).returncode, 2)

    def test_synthetic_option_is_exclusive_and_works_with_stdin(self):
        source = document(word("あ", "0", "0") + word("漢", "0", "0") + word("い", "0", "0"))
        result = self.run_cli("--synthetic-timing", data=source)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(read_words(result.stdout), ["a", "i"])
        self.assertIn("临时时间戳", result.stderr.decode())
        result = self.run_cli("--synthetic-timing", "--allow-ambiguous-timing", data=source)
        self.assertEqual(result.returncode, 2)
        with self.assertRaisesRegex(ValueError, "不能同时"):
            roman.convert(source, synthetic_timing=True, allow_ambiguous_timing=True)


if __name__ == "__main__":
    unittest.main()
