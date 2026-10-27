"""Desktop editor for the 12x12 squeezed Hangeul2 johap pieces and the English glyphs.

The left list has the Hangul pieces (initials, vowels, finals) and the English side:
digits, upper case, lower case and symbols. An English glyph is 6 pixels wide and 10 rows
high; on the screen it sits in the lower 10 rows of a 12-row cell.

The selected letter and the title of its group are highlighted in the list. The lower right panel shows
every letter that uses the piece being edited (the edited pixels in yellow, the rest in grey).

Run with the project virtual environment:
  .venv\\Scripts\\python.exe src\\fonteditor\\editor.py
"""
from __future__ import annotations

import json
import shutil
import tkinter as tk
from pathlib import Path
from tkinter import font as tkfont

HERE = Path(__file__).resolve().parent
FONT_PATH = HERE / "font.json"
CELL = 28
SCALE = 5
INK = "#ffd678"
OTHER = "#3d4f46"
BOTH = "#f4f1e4"
BG = "#0c0e12"
PANEL = "#161a22"
LINE = "#2a3140"
TEXT = "#d7ddd6"
MUTED = "#8b978f"
HILITE_BG = "#ffd678"       # background of the selected letter and of its group title
HILITE_FG = "#1a1400"
USES_OTHER = "#7f948b"      # the other pieces (or the neighbour letter) in the "letters that use this" sheet
USES_CELL = 14               # one letter cell: 12 pixels and a gap, before zooming
USES_ZOOM = 2


ASCII_GROUPS = [
    ("Digits", range(0x30, 0x3A)),
    ("Upper case", range(0x41, 0x5B)),
    ("Lower case", range(0x61, 0x7B)),
    ("Symbols", [c for c in range(0x21, 0x7F) if not chr(c).isalnum()]),
]


def hangul(c: int, v: int, t: int) -> str:
    return chr(0xAC00 + (c * 21 + v) * 28 + t)


class Editor(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.title("Squeezed 12x12")
        self.configure(bg=BG)
        self.font = json.loads(FONT_PATH.read_text(encoding="utf-8"))
        self.sel = {"role": "cho", "bank": 0, "index": 0}
        self.undo: list[list[int]] = []
        self.drag: bool | None = None
        self.changed = False
        self.ui_font = tkfont.Font(family="Malgun Gothic", size=11)
        self.small = tkfont.Font(family="Segoe UI", size=9)
        self.jamo_font = tkfont.Font(family="Malgun Gothic", size=12)
        self.jamo_bold = tkfont.Font(family="Malgun Gothic", size=12, weight="bold")
        self.small_bold = tkfont.Font(family="Segoe UI", size=9, weight="bold")
        self.title_font = tkfont.Font(family="Malgun Gothic", size=15, weight="bold")
        self.group_labels: dict[tuple, tk.Label] = {}
        self.button_group: dict[tuple, tk.Label] = {}
        self._uses_job = None
        self._uses_img = None
        self._build()
        self._select("cho", 0, 0)
        self.bind("<Control-s>", self._save)
        self.bind("<Control-z>", self._undo)

    def _dims(self) -> tuple[int, int]:
        """Columns and rows of the glyph being edited."""
        return (6, 10) if self.sel["role"] == "ascii" else (12, 12)

    def _rows(self) -> list[int]:
        sel = self.sel
        if sel["role"] == "ascii":
            return self.font["ascii"][sel["index"]]
        if sel["role"] == "cho":
            return self.font["cho"][sel["bank"]][sel["index"]]
        if sel["role"] == "jung":
            return self.font["jung"][sel["bank"]][sel["index"]]
        return self.font["jong"][sel["index"]]

    def _orig(self) -> list[int]:
        sel = self.sel
        if sel["role"] == "ascii":
            return self.font["orig"]["ascii"][sel["index"]]
        if sel["role"] == "cho":
            return self.font["orig"]["cho"][sel["bank"]][sel["index"]]
        if sel["role"] == "jung":
            return self.font["orig"]["jung"][sel["bank"]][sel["index"]]
        return self.font["orig"]["jong"][sel["index"]]

    def _compose(self, ch: str) -> list[int] | None:
        n = ord(ch) - 0xAC00
        if not 0 <= n <= 11171:
            return None
        c, v, t = n // 588, (n // 28) % 21, n % 28
        cl = self.font["jungClass"][v + 1] + (3 if t else 0)
        rows = [a | b for a, b in zip(self.font["cho"][cl][c], self.font["jung"][1 if t else 0][v])]
        if t:
            rows = [a | b for a, b in zip(rows, self.font["jong"][t - 1])]
        return rows

    def _context(self) -> str:
        sel = self.sel
        if sel["role"] == "cho":
            return hangul(sel["index"], (0, 8, 9)[sel["bank"] % 3], 4 if sel["bank"] >= 3 else 0)
        if sel["role"] == "jung":
            return hangul(0, sel["index"], 4 if sel["bank"] else 0)
        return hangul(0, 0, sel["index"] + 1)

    def _other(self) -> list[int]:
        if self.sel["role"] == "ascii":
            return [0] * 10
        ch = self._context()
        n = ord(ch) - 0xAC00
        c, v, t = n // 588, (n // 28) % 21, n % 28
        cl = self.font["jungClass"][v + 1] + (3 if t else 0)
        rows = [0] * 12
        parts = []
        if self.sel["role"] != "cho":
            parts.append(self.font["cho"][cl][c])
        if self.sel["role"] != "jung":
            parts.append(self.font["jung"][1 if t else 0][v])
        if self.sel["role"] != "jong" and t:
            parts.append(self.font["jong"][t - 1])
        for part in parts:
            rows = [a | b for a, b in zip(rows, part)]
        return rows

    def _build(self) -> None:
        top = tk.Frame(self, bg=BG)
        top.pack(fill="x", padx=12, pady=8)
        tk.Label(top, text="Squeezed 12x12", bg=BG, fg=TEXT, font=("Segoe UI", 12, "bold")).pack(side="left")
        tk.Label(
            top, text="  Edit one Hangul piece (the preview ORs it with the other two) or one English glyph.",
            bg=BG, fg=MUTED, font=self.small,
        ).pack(side="left")
        tk.Button(top, text="Save", command=self._save, bg=PANEL, fg=TEXT, relief="flat", padx=10).pack(side="left", padx=12)
        self.status = tk.Label(top, text="", bg=BG, fg=MUTED, font=self.small)
        self.status.pack(side="left")

        body = tk.Frame(self, bg=BG)
        body.pack(fill="both", expand=True)

        left = tk.Frame(body, bg=PANEL, width=340)
        left.pack(side="left", fill="y")
        left.pack_propagate(False)
        scroll = tk.Canvas(left, bg=PANEL, highlightthickness=0, width=320)
        bar = tk.Scrollbar(left, orient="vertical", command=scroll.yview)
        scroll.configure(yscrollcommand=bar.set)
        bar.pack(side="right", fill="y")
        scroll.pack(side="left", fill="both", expand=True)
        inner = tk.Frame(scroll, bg=PANEL)
        window = scroll.create_window((0, 0), window=inner, anchor="nw")

        def fit(_event=None) -> None:
            scroll.configure(scrollregion=scroll.bbox("all"))
            scroll.itemconfigure(window, width=scroll.winfo_width())

        inner.bind("<Configure>", fit)
        scroll.bind("<Configure>", fit)

        def wheel(event) -> None:
            scroll.yview_scroll(int(-event.delta / 120), "units")

        scroll.bind("<Enter>", lambda _e: scroll.bind_all("<MouseWheel>", wheel))
        scroll.bind("<Leave>", lambda _e: scroll.unbind_all("<MouseWheel>"))
        self.list_canvas = scroll
        self.list_inner = inner
        self.buttons: dict[tuple, tk.Button] = {}
        self._banks(inner)

        center = tk.Frame(body, bg=BG, padx=16)
        center.pack(side="left", fill="y")
        self.title_label = tk.Label(center, text="", bg=BG, fg=INK, font=self.title_font, wraplength=360, justify="left")
        self.title_label.pack(anchor="w", pady=(0, 8))
        tools = tk.Frame(center, bg=BG)
        tools.pack(anchor="w")
        tk.Button(tools, text="Undo", command=self._undo, bg=PANEL, fg=TEXT, relief="flat", padx=8).pack(side="left")
        tk.Button(tools, text="Revert piece", command=self._revert, bg=PANEL, fg=TEXT, relief="flat", padx=8).pack(side="left", padx=8)
        self.grid = tk.Canvas(center, width=CELL * 12, height=CELL * 12, bg=BG, highlightthickness=1, highlightbackground=LINE)
        self.grid.pack(anchor="w", pady=10)
        self.grid.bind("<Button-1>", lambda e: self._down(e, True))
        self.grid.bind("<B1-Motion>", lambda e: self._move(e))
        self.grid.bind("<ButtonRelease-1>", lambda e: self._up())
        self.grid.bind("<Button-3>", lambda e: self._down(e, False))
        self.grid.bind("<B3-Motion>", lambda e: self._move(e))
        self.grid.bind("<ButtonRelease-3>", lambda e: self._up())
        tk.Label(
            center,
            text="Left drag draws. Right drag erases.\nGray belongs to the other pieces. White means both.",
            bg=BG, fg=MUTED, font=self.small, justify="left",
        ).pack(anchor="w")

        right = tk.Frame(body, bg=BG, padx=8)
        right.pack(side="left", fill="both", expand=True)
        tk.Label(right, text="Preview text", bg=BG, fg=MUTED, font=self.small).pack(anchor="w")
        self.sample = tk.Text(
            right, height=3, wrap="char", bg=PANEL, fg=TEXT, insertbackground=TEXT,
            font=self.ui_font, relief="flat",
        )
        self.sample.insert("1.0", "똥롤않쌌꽦가나다 ABC abc 0O1lI| 123 !?@#")
        self.sample.pack(anchor="w", fill="x", pady=4)
        self.sample.bind("<KeyRelease>", lambda _e: self._preview())
        self.preview = tk.Canvas(right, bg=BG, highlightthickness=0)
        self.preview.pack(anchor="w", fill="both", expand=True, pady=8)
        self.preview.bind("<Configure>", lambda _e: self._preview())
        self.uses_title = tk.Label(right, text="", bg=BG, fg=INK, font=self.small_bold, anchor="w", justify="left", wraplength=420)
        self.uses_title.pack(anchor="w", fill="x")
        uses_box = tk.Frame(right, bg=PANEL)
        uses_box.pack(side="top", fill="both", expand=True, pady=(2, 8))
        uses_bar = tk.Scrollbar(uses_box, orient="vertical")
        uses_bar.pack(side="right", fill="y")
        self.uses = tk.Canvas(uses_box, bg=BG, highlightthickness=0, yscrollcommand=uses_bar.set)
        self.uses.pack(side="left", fill="both", expand=True)
        uses_bar.configure(command=self.uses.yview)
        self.uses.bind("<Configure>", lambda _e: self._uses_later())
        self.uses.bind("<Enter>", lambda _e: self.uses.bind_all("<MouseWheel>", lambda ev: self.uses.yview_scroll(int(-ev.delta / 120), "units")))
        self.uses.bind("<Leave>", lambda _e: self.uses.unbind_all("<MouseWheel>"))
        self.path_label = tk.Label(
            right, text=str(FONT_PATH), bg=BG, fg=MUTED, font=self.small,
            anchor="w", justify="left",
        )
        self.path_label.pack(side="bottom", fill="x", pady=(8, 4))
        right.bind("<Configure>", lambda e: self.path_label.configure(wraplength=max(120, e.width - 16)))

    def _banks(self, parent: tk.Frame) -> None:
        groups = [("cho", bank, label, self.font["choNames"]) for bank, label in enumerate(self.font["choLabels"])]
        groups += [("jung", bank, label, self.font["jungNames"]) for bank, label in enumerate(self.font["jungLabels"])]
        groups.append(("jong", 0, self.font["jongLabel"], self.font["jongNames"]))
        for label, codes in ASCII_GROUPS:
            groups.append(("ascii", 0, "English: " + label, {c: chr(c) for c in codes}))
        for role, bank, label, names in groups:
            title = tk.Label(parent, text=label, bg=PANEL, fg=MUTED, font=self.small, wraplength=300, justify="left", anchor="w")
            title.pack(anchor="w", fill="x", padx=8, pady=(10, 2))
            self.group_labels[(role, bank, label)] = title
            row = tk.Frame(parent, bg=PANEL)
            row.pack(anchor="w", padx=8)
            items = list(names.items()) if isinstance(names, dict) else list(enumerate(names))
            for pos, (index, name) in enumerate(items):
                if pos and pos % 10 == 0:
                    row = tk.Frame(parent, bg=PANEL)
                    row.pack(anchor="w", padx=8)
                btn = tk.Button(
                    row, text=name, width=2, font=self.jamo_font,
                    bg=PANEL, fg=TEXT, relief="flat",
                    command=lambda r=role, b=bank, i=index: self._select(r, b, i),
                )
                btn.pack(side="left", padx=1, pady=1)
                self.buttons[(role, bank, index)] = btn
                self.button_group[(role, bank, index)] = title

    def _select(self, role: str, bank: int, index: int) -> None:
        for btn in self.buttons.values():
            btn.configure(bg=PANEL, fg=TEXT, font=self.jamo_font, activebackground=LINE)
        for lab in self.group_labels.values():
            lab.configure(bg=PANEL, fg=MUTED, font=self.small)
        chosen = self.buttons[(role, bank, index)]
        chosen.configure(bg=HILITE_BG, fg=HILITE_FG, font=self.jamo_bold, activebackground=HILITE_BG)
        self.button_group[(role, bank, index)].configure(bg=HILITE_BG, fg=HILITE_FG, font=self.small_bold)
        self.sel = {"role": role, "bank": bank, "index": index}
        self.after(30, lambda: self._see(role, bank, index))
        self.undo.clear()
        if role == "ascii":
            self.title_label.configure(text=f"English   {chr(index)}   (ASCII ${index:02X})")
        else:
            names = {"cho": self.font["choNames"], "jung": self.font["jungNames"], "jong": self.font["jongNames"]}
            labels = {"cho": self.font["choLabels"], "jung": self.font["jungLabels"], "jong": [self.font["jongLabel"]]}
            self.title_label.configure(text=f"{labels[role][bank]}   {names[role][index]}")
        self._redraw()
        self._preview()

    def _see(self, role: str, bank: int, index: int) -> None:
        """Scroll the left list so the selected letter and its group title are visible."""
        try:
            canvas = self.list_canvas
            canvas.update_idletasks()
            btn = self.buttons[(role, bank, index)]
            top = self.button_group[(role, bank, index)].winfo_y()
            bottom = btn.master.winfo_y() + btn.winfo_y() + btn.winfo_height()
            total = max(1, self.list_inner.winfo_height())
            view_top = canvas.canvasy(0)
            view_h = canvas.winfo_height()
            if top < view_top or bottom > view_top + view_h - 24:
                canvas.yview_moveto(max(0.0, (top - 8) / total))
        except tk.TclError:
            pass

    def _uses_cells(self) -> tuple[str, list[list[tuple[int, int]]]]:
        """The letters that use the selected piece, as cells of 12 rows. Each row is (edited, other): bit masks of
        the 12 columns. The edited pixels are yellow, the pixels of the other pieces (or of the neighbour
        character, for English) are grey."""
        sel = self.sel
        role = sel["role"]
        cells: list[list[tuple[int, int]]] = []
        if role == "ascii":
            code = sel["index"]
            mine = self.font["ascii"][code]
            for other in range(0x21, 0x7F):
                og = self.font["ascii"][other]
                for mine_left in (True, False):
                    cell = []
                    for y in range(12):
                        gy = y - 2
                        a = mine[gy] if 0 <= gy < 10 else 0
                        b = og[gy] if 0 <= gy < 10 else 0
                        cell.append((a, b << 6) if mine_left else (a << 6, b))
                    cells.append(cell)
            return f"English {chr(code)}: next to every other character, on the left and on the right ({len(cells)} pairs)", cells
        jc = self.font["jungClass"]
        for c in range(19):
            for v in range(21):
                for t in range(28):
                    cl = jc[v + 1] + (3 if t else 0)
                    if role == "cho" and not (c == sel["index"] and cl == sel["bank"]):
                        continue
                    if role == "jung" and not (v == sel["index"] and (1 if t else 0) == sel["bank"]):
                        continue
                    if role == "jong" and t != sel["index"] + 1:
                        continue
                    parts = [("cho", self.font["cho"][cl][c]), ("jung", self.font["jung"][1 if t else 0][v])]
                    if t:
                        parts.append(("jong", self.font["jong"][t - 1]))
                    mine_rows = [0] * 12
                    other_rows = [0] * 12
                    for name, rows in parts:
                        target = mine_rows if name == role else other_rows
                        for y in range(12):
                            target[y] |= rows[y]
                    cells.append([(mine_rows[y], other_rows[y]) for y in range(12)])
        names = {"cho": "initial", "jung": "vowel", "jong": "final"}[role]
        return f"Letters that use this {names} piece: {len(cells)} syllables (edited pixels yellow, other pieces grey)", cells

    def _uses_later(self) -> None:
        if self._uses_job is not None:
            self.after_cancel(self._uses_job)
        self._uses_job = self.after(150, self._draw_uses)

    def _draw_uses(self) -> None:
        self._uses_job = None
        title, cells = self._uses_cells()
        self.uses_title.configure(text=title)
        width = max(self.uses.winfo_width(), USES_CELL * USES_ZOOM)
        cols = max(1, width // (USES_CELL * USES_ZOOM))
        rows_n = max(1, (len(cells) + cols - 1) // cols)
        wpx, hpx = cols * USES_CELL, rows_n * USES_CELL
        pixels = [[BG] * wpx for _ in range(hpx)]
        for n, cell in enumerate(cells):
            ox, oy = (n % cols) * USES_CELL, (n // cols) * USES_CELL
            for y, (mine, other) in enumerate(cell):
                line = pixels[oy + y]
                for x in range(12):
                    a, b = mine >> x & 1, other >> x & 1
                    if a:
                        line[ox + x] = BOTH if b else INK
                    elif b:
                        line[ox + x] = USES_OTHER
        img = tk.PhotoImage(width=wpx, height=hpx)
        img.put(tuple(tuple(r) for r in pixels), to=(0, 0))
        self._uses_img = img.zoom(USES_ZOOM)
        self.uses.delete("all")
        self.uses.create_image(0, 0, image=self._uses_img, anchor="nw")
        self.uses.configure(scrollregion=(0, 0, wpx * USES_ZOOM, hpx * USES_ZOOM))

    def _redraw(self) -> None:
        mine = self._rows()
        other = self._other()
        self.grid.delete("all")
        gw, gh = self._dims()
        for y in range(gh):
            for x in range(gw):
                bit = 1 << x
                on = mine[y] & bit
                dim = other[y] & bit
                color = BOTH if on and dim else INK if on else OTHER if dim else BG
                self.grid.create_rectangle(
                    x * CELL, y * CELL, (x + 1) * CELL, (y + 1) * CELL,
                    fill=color, outline="#222833",
                )

    def _ascii_glyph(self, ch: str) -> list[int] | None:
        code = ord(ch)
        if 32 <= code < 127 and code != 32:
            return self.font["ascii"][code]
        return None

    def _preview(self) -> None:
        """Lay the sample out like the screen: a Hangul syllable takes 12 pixels, an English character 6."""
        self._uses_later()
        text = self.sample.get("1.0", "end-1c")
        scale = 4
        width = max(self.preview.winfo_width(), 12 * scale)
        line_px = max(12, min(276, width // scale))      # the screen is 46 columns of 6 pixels
        self.preview.delete("all")
        x = y = 0
        row_h = 14 * scale
        for ch in text:
            if ch == chr(10):
                x, y = 0, y + row_h
                continue
            rows = self._compose(ch)
            w, off, glyph = 12, 0, rows
            if rows is None:
                glyph = self._ascii_glyph(ch)
                w, off = 6, 2
                if glyph is None:
                    glyph = [0] * 10
                    if ch != " ":
                        continue
            if x + w > line_px:
                x, y = 0, y + row_h
            for gy, bits in enumerate(glyph):
                for gx in range(w):
                    if bits >> gx & 1:
                        self.preview.create_rectangle(
                            (x + gx) * scale, y + (gy + off) * scale,
                            (x + gx + 1) * scale, y + (gy + off + 1) * scale,
                            fill=INK, outline="",
                        )
            x += w

    def _cell(self, event) -> tuple[int, int] | None:
        x, y = event.x // CELL, event.y // CELL
        gw, gh = self._dims()
        if 0 <= x < gw and 0 <= y < gh:
            return x, y
        return None

    def _down(self, event, draw: bool) -> None:
        hit = self._cell(event)
        if hit is None:
            return
        x, y = hit
        self.undo.append(self._rows().copy())
        if len(self.undo) > 80:
            self.undo.pop(0)
        on = (self._rows()[y] >> x & 1) == 1
        self.drag = (not on) if draw else False
        self.changed = False
        self._paint(x, y)

    def _move(self, event) -> None:
        if self.drag is None:
            return
        hit = self._cell(event)
        if hit:
            self._paint(*hit)

    def _up(self) -> None:
        if self.drag is not None and not self.changed and self.undo:
            self.undo.pop()
        self.drag = None

    def _paint(self, x: int, y: int) -> None:
        rows = self._rows()
        bit = 1 << x
        has = (rows[y] & bit) != 0
        if has == self.drag:
            return
        rows[y] = (rows[y] | bit) if self.drag else (rows[y] & ~bit)
        self.changed = True
        self.status.configure(text="Unsaved")
        self._redraw()
        self._preview()

    def _undo(self, _event=None):
        if not self.undo:
            return "break"
        self._rows()[:] = self.undo.pop()
        self.status.configure(text="Unsaved")
        self._redraw()
        self._preview()
        return "break"

    def _revert(self) -> None:
        self.undo.append(self._rows().copy())
        self._rows()[:] = self._orig()
        self.status.configure(text="Unsaved")
        self._redraw()
        self._preview()

    def _save(self, _event=None):
        current = json.loads(FONT_PATH.read_text(encoding="utf-8"))
        current["cho"] = self.font["cho"]
        current["jung"] = self.font["jung"]
        current["jong"] = self.font["jong"]
        current["ascii"] = self.font["ascii"]
        shutil.copyfile(FONT_PATH, HERE / "font.prev.json")
        FONT_PATH.write_text(json.dumps(current, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
        self.status.configure(text="Saved")
        return "break"


if __name__ == "__main__":
    Editor().mainloop()
