"""
Thinkfinity — Procedural Level Generator (500 levels)
======================================================

This extends the original 100-level prototype script into a full
500-level generator that matches the difficulty arc described in the
Thinkfinity PRD (Easy 1-20 / Medium 21-40 / Hard 41-50 on a 50-level
scale -> proportionally scaled to 1-200 / 201-400 / 401-500 on 500).

ALGORITHM OVERVIEW
-------------------
1. CREATE BOARD
   Build an NxN grid of cells. Each cell has:
     - active: whether it's part of the puzzle (False = empty/hole,
       used to create non-square "image-shaped" boards)
     - conn:   a 4-bit bitmask of which sides have a road segment
               (UP=1, RIGHT=2, DOWN=4, LEFT=8)

2. MASK (carve holes)
   Randomly deactivate a percentage of cells (never the center) to
   create irregular board shapes, similar to how a split city image
   would not always be a perfect rectangle of usable tiles.

3. FIX CONNECTIVITY (bug fix vs. the original prototype)
   Masking can accidentally cut the board into disconnected islands.
   We flood-fill from the center over active cells and turn any
   unreachable active cell into a hole too. This guarantees that
   every active cell that remains is reachable, so the spanning-tree
   step below can never leave an active cell with conn == 0
   (a tile with no road on it at all).

4. SPANNING TREE (dfs)
   Depth-first search from the center cell. Every time we step from
   cell A to neighbour B, we set the matching bits on both cells
   (e.g. A gets RIGHT, B gets LEFT). This guarantees a single fully
   connected road network with no dead ends pointing off the board.

5. ADD EXTRA LOOPS
   With some probability per cell, add one extra connection to a
   neighbour that isn't already connected. This turns parts of the
   tree into actual loops/cycles, which is what makes the puzzle
   visually "Infinity-Loop"-like and creates multiple plausible (but
   wrong) rotations — i.e. real difficulty instead of just a maze.

6. SCRAMBLE
   Rotate each active tile's bitmask by 1-3 random 90° turns. Since
   rotation is reversible and bounded (4 possible states), every
   generated puzzle is guaranteed solvable by construction — you can
   always rotate any tile back to its original, correct orientation.

7. DIFFICULTY SCALING (new)
   grid size, hole %, extra-loop probability, and time limit are all
   interpolated smoothly across three phases (easy/medium/hard) so
   that level 1 and level 500 sit at opposite ends of a continuous
   difficulty curve instead of jumping in steps.

8. EXPORT
   Each level is written as its own JSON file (rows, cols, per-cell
   bitmask, time_limit, theme, phase) plus a manifest.json index of
   all 500 levels for a level-select screen.

WIN CONDITION (used by the game, not the generator):
   A board is "solved" when, for every active cell and every bit set
   in its conn mask, the neighbour in that direction exists, is
   active, and has the matching reciprocal bit set. This is checked
   live in Godot after every tap — see scripts/GameManager.gd.
"""

import random
import json
import os

UP, RIGHT, DOWN, LEFT = 1, 2, 4, 8

DIRS = [
    (-1, 0, UP, DOWN),
    (0, 1, RIGHT, LEFT),
    (1, 0, DOWN, UP),
    (0, -1, LEFT, RIGHT),
]

TOTAL_LEVELS = 20
OUTPUT_DIR = "levels"

# Difficulty phases, scaled from the original 50-level arc (40% / 40% / 20%)
PHASE_EASY_END = int(TOTAL_LEVELS * 0.40)     # levels 1-200
PHASE_MEDIUM_END = int(TOTAL_LEVELS * 0.80)   # levels 201-400
# remaining levels (401-500) are HARD


def lerp(a, b, t):
    return a + (b - a) * t


def get_phase(level):
    """Returns (phase_name, t) where t in [0,1] is progress within the phase."""
    if level <= PHASE_EASY_END:
        return "easy", (level - 1) / max(PHASE_EASY_END - 1, 1)
    elif level <= PHASE_MEDIUM_END:
        return "medium", (level - PHASE_EASY_END - 1) / max(PHASE_MEDIUM_END - PHASE_EASY_END - 1, 1)
    else:
        return "hard", (level - PHASE_MEDIUM_END - 1) / max(TOTAL_LEVELS - PHASE_MEDIUM_END - 1, 1)


def get_difficulty_params(level):
    """grid_size, hole percentage, extra-loop probability, and the two
    time-limit coefficients (flat base + per-active-cell), interpolated
    smoothly inside each phase."""
    phase, t = get_phase(level)

    if phase == "easy":
        size = round(lerp(4, 7, t))
        mask_pct = lerp(0.05, 0.12, t)
        loop_prob = lerp(0.05, 0.15, t)
        time_base, time_per_cell = lerp(15, 12, t), lerp(1.6, 1.3, t)
    elif phase == "medium":
        size = round(lerp(7, 9, t))
        mask_pct = lerp(0.12, 0.20, t)
        loop_prob = lerp(0.15, 0.30, t)
        time_base, time_per_cell = lerp(12, 10, t), lerp(1.3, 1.0, t)
    else:  # hard
        size = round(lerp(9, 11, t))
        mask_pct = lerp(0.20, 0.30, t)
        loop_prob = lerp(0.30, 0.45, t)
        time_base, time_per_cell = lerp(10, 8, t), lerp(1.0, 0.8, t)

    return size, mask_pct, loop_prob, time_base, time_per_cell, phase


def create_board(rows, cols):
    return [[{"active": True, "conn": 0} for _ in range(cols)] for _ in range(rows)]


def create_mask(board, percentage):
    rows, cols = len(board), len(board[0])
    total = rows * cols
    remove_count = int(total * percentage)
    center = (rows // 2, cols // 2)
    removed = 0
    attempts = 0
    while removed < remove_count and attempts < total * 10:
        attempts += 1
        r = random.randint(0, rows - 1)
        c = random.randint(0, cols - 1)
        if (r, c) == center:
            continue
        if board[r][c]["active"]:
            board[r][c]["active"] = False
            removed += 1


def flood_fill_reachable(board, start):
    rows, cols = len(board), len(board[0])
    visited = set()
    stack = [start]
    while stack:
        r, c = stack.pop()
        if (r, c) in visited or not board[r][c]["active"]:
            continue
        visited.add((r, c))
        for dr, dc, _, _ in DIRS:
            nr, nc = r + dr, c + dc
            if 0 <= nr < rows and 0 <= nc < cols and (nr, nc) not in visited:
                if board[nr][nc]["active"]:
                    stack.append((nr, nc))
    return visited


def remove_unreachable_islands(board, center):
    """Any active cell the mask disconnected from the center becomes a
    hole. Guarantees every remaining active cell is reachable, so dfs()
    below can never leave an active tile with conn == 0."""
    reachable = flood_fill_reachable(board, center)
    rows, cols = len(board), len(board[0])
    for r in range(rows):
        for c in range(cols):
            if board[r][c]["active"] and (r, c) not in reachable:
                board[r][c]["active"] = False
    return reachable


def dfs(board, r, c, visited):
    visited.add((r, c))
    neighbours = DIRS[:]
    random.shuffle(neighbours)
    rows, cols = len(board), len(board[0])
    for dr, dc, current_dir, neighbour_dir in neighbours:
        nr, nc = r + dr, c + dc
        if nr < 0 or nr >= rows or nc < 0 or nc >= cols:
            continue
        if not board[nr][nc]["active"] or (nr, nc) in visited:
            continue
        board[r][c]["conn"] |= current_dir
        board[nr][nc]["conn"] |= neighbour_dir
        dfs(board, nr, nc, visited)


def add_extra_loops(board, probability):
    rows, cols = len(board), len(board[0])
    for r in range(rows):
        for c in range(cols):
            if not board[r][c]["active"] or random.random() > probability:
                continue
            dirs = DIRS[:]
            random.shuffle(dirs)
            for dr, dc, current_dir, neighbour_dir in dirs:
                nr, nc = r + dr, c + dc
                if nr < 0 or nr >= rows or nc < 0 or nc >= cols:
                    continue
                if not board[nr][nc]["active"]:
                    continue
                if board[r][c]["conn"] & current_dir:
                    continue
                board[r][c]["conn"] |= current_dir
                board[nr][nc]["conn"] |= neighbour_dir
                break


def rotate90(value):
    return ((value << 1) | (value >> 3)) & 15


def scramble(board):
    """Scramble tiles 1–3 rotations. Returns solution grid (pre-scramble conn values)."""
    rows, cols = len(board), len(board[0])
    solution = [[0] * cols for _ in range(rows)]
    for r in range(rows):
        for c in range(cols):
            if not board[r][c]["active"]:
                continue
            solution[r][c] = board[r][c]["conn"]   # save correct orientation
            times = random.randint(1, 3)  # never 0, so a level never starts pre-solved
            value = board[r][c]["conn"]
            for _ in range(times):
                value = rotate90(value)
            board[r][c]["conn"] = value
    return solution


def export_level(board, level_number, time_limit, theme, phase, active_cells, solution_cells):
    rows, cols = len(board), len(board[0])
    cells = [[board[r][c]["conn"] if board[r][c]["active"] else 0 for c in range(cols)] for r in range(rows)]
    data = {
        "level": level_number,
        "phase": phase,
        "rows": rows,
        "cols": cols,
        "active_cells": active_cells,
        "time_limit": round(time_limit, 1),
        "theme": theme,
        "cells": cells,
        "solution": solution_cells,
    }
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    filename = os.path.join(OUTPUT_DIR, f"level_{level_number:03}.json")
    with open(filename, "w") as f:
        json.dump(data, f, indent=2)
    return data


def generate_level(level_number):
    size, mask_pct, loop_prob, time_base, time_per_cell, phase = get_difficulty_params(level_number)
    rows = cols = size

    board = create_board(rows, cols)
    create_mask(board, mask_pct)

    center = (rows // 2, cols // 2)
    reachable = remove_unreachable_islands(board, center)

    visited = set()
    dfs(board, center[0], center[1], visited)
    add_extra_loops(board, loop_prob)
    solution = scramble(board)

    active_cells = len(reachable)
    time_limit = time_base + active_cells * time_per_cell
    theme = ((level_number - 1) % 5) + 1  # cycle through the 5 PRD sub-themes

    return export_level(board, level_number, time_limit, theme, phase, active_cells, solution)


def generate_all_levels(total=TOTAL_LEVELS, seed=None):
    if seed is not None:
        random.seed(seed)
    manifest = []
    for level in range(1, total + 1):
        data = generate_level(level)
        manifest.append({
            "level": data["level"],
            "phase": data["phase"],
            "grid": f'{data["rows"]}x{data["cols"]}',
            "active_cells": data["active_cells"],
            "time_limit": data["time_limit"],
            "theme": data["theme"],
        })
    with open(os.path.join(OUTPUT_DIR, "manifest.json"), "w") as f:
        json.dump(manifest, f, indent=2)
    print(f"{total} levels generated in '{OUTPUT_DIR}/'")


if __name__ == "__main__":
    generate_all_levels()
