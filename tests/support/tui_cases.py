"""PTY scenario inputs; the terminal driver contains no feature-specific branches."""

from dataclasses import dataclass, field


@dataclass(frozen=True)
class Stage:
    file: str
    actions: dict = field(default_factory=dict)
    input_file: str = ""
    resize_file: str = ""
    vim_keys: bool = False


@dataclass(frozen=True)
class Scenario:
    file: str
    env: dict = field(default_factory=dict)
    defaults: dict = field(default_factory=dict)
    columns: int = 120
    timeout: float = 30
    stage: object = None
    document: str = ""
    text: str = ""


KEYMAP_ACTIONS = {
    "prefix": b" ",
    "subgroup": b"s",
    "hint_cancel": b"\x1b",
    "confirm": b"\r",
    "visual_cancel": b"\x1b",
    "visual_escape": b"\x1b",
    "operator_prefix": b"d",
    "object_prefix": b"i",
    "object_apply": b"(",
    "insert_register": b"i\x12",
    "insert_register_apply": b"z",
    "leave_insert": b"\x1b",
    "command_register": b":\x12",
    "command_register_apply": b"z",
    "command_cancel": b"\x1b",
}

ANNOTATION_ACTIONS = {
    "insert": b"3GA TODO: live #abcdef",
    "burst": b" xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    b"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    b"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    b"xxxxxxxxx #00ff00",
    "normal": b"\x1b",
}

TASK_ACTIONS = {
    "command": b"\x15printf 'src/failure.c:2:3: error: demo\\n'\r",
    "jump": b"\r",
    "terminal_input": b"printf 'TASKS_PTY_OK\\n'\r",
    "list_close": b"q",
    "args_normal": b"\x1d",
    "args_close": b"q",
    "task_choice": b"Python: run file\r",
    "args": b"'hello world' \"\"\r",
}

TOOLCHAIN_ACTIONS = {
    "plan": b"q",
    "install": b":ConfigToolsInstall\r",
    "tasks": b"\r",
    "retry": b"r",
    "close": b"q",
}

SCENARIOS = {
    name: Scenario(file)
    for name, file in {
        "markdown_tools": "markdown_tools_tui.lua",
        "markdown_direct": "markdown_demand.lua",
        "markdown_demand": "markdown_demand.lua",
        "demand": "demand_startup.lua",
        "python_environment": "python_environment_tui.lua",
        "native_utilities": "native_utilities_tui.lua",
        "editing_input": "editing_tui.lua",
        "tasks": "tasks_tui.lua",
        "motion": "motion_tui.lua",
        "notifications": "notifications_tui.lua",
        "notification_picker": "notification_picker_tui.lua",
        "ui_tools": "ui_tools_tui.lua",
        "annotations": "annotations_tui.lua",
        "bars": "bars_tui.lua",
        "folding": "folding_tui.lua",
        "completion_input": "completion_tui.lua",
        "copilot": "copilot_tui.lua",
        "keymaps": "keymaps_tui.lua",
        "toolchain": "toolchain_tui.lua",
        "nested_keymaps": "nested_keymaps_tui.lua",
        "health": "health_tui.lua",
        "completion_policy": "completion_policy_tui.lua",
        "boundaries": "lifecycle_startup.lua",
        "boundaries_files": "lifecycle_startup.lua",
        "editing": "lifecycle_startup.lua",
        "completion": "lifecycle_startup.lua",
        "image_plain": "image_loading_tui.lua",
        "image_edit": "image_loading_tui.lua",
        "image_existing": "image_loading_tui.lua",
        "image_tex_reference": "image_loading_tui.lua",
        "image_typst_reference": "image_loading_tui.lua",
        "image_markdown_formula": "image_loading_tui.lua",
        "image_disabled": "image_loading_tui.lua",
        "image_formula": "image_loading_tui.lua",
        "image_file": "image_loading_tui.lua",
    }.items()
}


def configure(name, **options):
    original = SCENARIOS[name]
    SCENARIOS[name] = Scenario(original.file, **options)


configure("completion_policy", env={"NVIM_TEST_SCENARIO": "writing"})
configure(
    "python_environment",
    env={"NVIM_TEST_SCENARIO": "python_environment"},
    timeout=50,
    stage=Stage(
        "python-stage",
        {
            "open": b" cv",
            "choose": b"chosen\r",
            "open_other": b" cv",
            "cancel": b"\x1b",
        },
    ),
)
configure("native_utilities", env={"NVIM_TEST_SCENARIO": "lua"})
for name in SCENARIOS:
    if name.startswith("image_"):
        configure(name, env={"NVIM_TEST_SCENARIO": "writing"})
for name in (
    "notifications",
    "notification_picker",
    "ui_tools",
    "completion_input",
    "bars",
    "folding",
    "toolchain",
    "annotations",
    "health",
):
    configure(
        name,
        env={"NVIM_TEST_SCENARIO": "minimal"},
        columns=160 if name in ("ui_tools", "bars", "folding") else 120,
    )
configure(
    "motion", defaults={"NVIM_TEST_SCENARIO": "minimal"}, stage=Stage("motion-stage")
)
configure("editing_input", stage=Stage("editing-stage"))
configure("markdown_tools", stage=Stage("markdown-stage"))
configure("tasks", stage=Stage("tasks-stage", TASK_ACTIONS))
configure(
    "annotations",
    env={"NVIM_TEST_SCENARIO": "minimal"},
    stage=Stage("annotations-stage", ANNOTATION_ACTIONS),
)
configure(
    "toolchain",
    env={"NVIM_TEST_SCENARIO": "minimal"},
    stage=Stage("toolchain-stage", TOOLCHAIN_ACTIONS),
)
configure("keymaps", stage=Stage("keymap-stage", KEYMAP_ACTIONS))
configure(
    "health",
    env={"NVIM_TEST_SCENARIO": "minimal"},
    stage=Stage("health-stage", vim_keys=True),
)
configure(
    "nested_keymaps", stage=Stage("stage", input_file="input", resize_file="resize")
)
configure(
    "markdown_direct",
    env={"NVIM_TEST_MARKDOWN_DIRECT": "1"},
    document="first.md",
    text="# Demand Markdown\n\nplain source\n\n- first\n- second\n",
)

FILES = {name: scenario.file for name, scenario in SCENARIOS.items()}
