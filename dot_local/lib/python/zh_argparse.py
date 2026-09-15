"""让 argparse 的内置文案显示中文。"""
import argparse

_ZH = {
    # ---- HelpFormatter ----
    "usage: ": "用法：",
    "positional arguments": "位置参数",
    "options": "选项",
    "optional arguments": "可选参数",          # Python < 3.10
    "show this help message and exit": "显示此帮助信息并退出",

    # ---- parser.error / exit ----
    "%(prog)s: error: %(message)s\n": "%(prog)s：错误：%(message)s\n",
    "the following arguments are required: %s": "缺少必需参数：%s",
    "one of the arguments %s is required": "参数 %s 中必须有一个",
    "unrecognized arguments: %s": "无法识别的参数：%s",

    # ---- 参数值校验 ----
    "expected one argument": "需要一个参数值",
    "expected at most one argument": "最多一个参数值",
    "expected at least one argument": "至少一个参数值",
    "ignored explicit argument %r": "忽略了显式参数 %r",
    "invalid choice: %(value)r (choose from %(choices)s)":
        "无效选择：%(value)r（可选：%(choices)s）",
    "argument %(argument_name)s: %(message)s":
        "参数 %(argument_name)s：%(message)s",
    "not allowed with argument %s": "不能与参数 %s 同时使用",
    "ambiguous option: %(option)s could match %(matches)s":
        "选项有歧义：%(option)s 可匹配 %(matches)s",
    "invalid %(type)s value: %(value)r":
        "无效的 %(type)s 值：%(value)r",

    # ---- ngettext 的 singular（中文无复数）----
    "expected %s argument": "需要 %s 个参数值",
}


def _zh(s: str) -> str:
    return _ZH.get(s, s)


def install_zh_argparse() -> None:
    """在构造 ArgumentParser 之前调用一次即可。"""
    argparse._ = _zh
    # 中文没有复数，直接用单数模板（同一 msgid 的 singular 形式）
    argparse.ngettext = lambda singular, plural, n: _zh(singular)
