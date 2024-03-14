from etyviz.utils import File


def test_get_lines():
    lines = list(File("tests/utils/lines_test.in").all_lines())
    assert lines[0] == "This is the first line.\n"
    assert lines[1] == "This is the second line.\n"


def test_from_lines():
    file = File.from_lines("tests/utils/from_lines.out", ["First", "Second"])
    lines = list(file.get_lines())
    assert lines[0] == "First\n"
    assert lines[1] == "Second\n"


def test_mutate():
    file_out = File("tests/utils/lines_test.in").mutate(
        "tests/utils/test_mutated.out", lambda x: "asd" + x
    )
    lines = list(file_out.get_lines())
    assert lines[0] == "asdThis is the first line.\n"
    assert lines[1] == "asdThis is the second line.\n"
