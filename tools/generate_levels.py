import json, math, random
from collections import deque

UP, RIGHT, DOWN, LEFT = 1, 2, 4, 8
OPP = {UP: DOWN, DOWN: UP, LEFT: RIGHT, RIGHT: LEFT}
DIRS = [(-1, 0, UP, DOWN), (0, 1, RIGHT, LEFT), (1, 0, DOWN, UP), (0, -1, LEFT, RIGHT)]


def rotate90(v):
    return ((v << 1) | (v >> 3)) & 15


def popcount(v):
    return bin(v).count("1")


PATTERNS = [
    "winding", "hLanes", "zigzag", "spiral", "concentric",
    "ring", "diagonal", "checkerboard", "gridLoops", "braid", "denseMaze",
    "staircase", "pinwheel", "waves", "herringbone", "cross",
]

# ---------------------------------------------------------------------------
# Mask (holes) generation — interior holes only, never a fully-emptied
# row or column.
# ---------------------------------------------------------------------------

def build_mask(rows, cols, pct, rng, pattern):
    active = [[True] * cols for _ in range(rows)]
    if pct <= 0:
        return active
    total = rows * cols
    target_remove = int(total * pct)
    cr, cc = (rows - 1) / 2.0, (cols - 1) / 2.0
    max_d = math.hypot(cr, cc) or 1.0

    # A row/column may never be fully punched out — keep at least 40%
    # (min 2) of its cells active, so holes always sit "in the middle"
    # of a row/column rather than wiping it out.
    row_cap = max(1, cols - max(2, math.ceil(cols * 0.4)))
    col_cap = max(1, rows - max(2, math.ceil(rows * 0.4)))
    row_removed = [0] * rows
    col_removed = [0] * cols

    cells = []
    for r in range(rows):
        for c in range(cols):
            d = math.hypot(r - cr, c - cc) / max_d
            interior = not (r in (0, rows - 1) or c in (0, cols - 1))
            w = (1.0 - d) * 0.4
            if interior:
                w += 0.3   # bias holes toward the middle of rows/columns
            if pattern in ("concentric", "ring"):
                ring = min(r, c, rows - 1 - r, cols - 1 - c)
                w += 0.15 if ring % 2 == 1 else -0.05
            elif pattern == "checkerboard":
                w += 0.15 if (r + c) % 2 == 0 else -0.05
            elif pattern == "diagonal":
                w += 0.15 if abs(r - c) % 3 == 0 else 0.0
            elif pattern == "cross":
                on_axis = (r == round(cr)) or (c == round(cc))
                w -= 0.3 if on_axis else 0.0
            cells.append((w + rng.random() * 0.4, r, c))
    cells.sort(key=lambda t: -t[0])

    removed = 0
    for _, r, c in cells:
        if removed >= target_remove:
            break
        if abs(r - cr) < 0.6 and abs(c - cc) < 0.6:
            continue  # keep the exact center open
        if row_removed[r] >= row_cap or col_removed[c] >= col_cap:
            continue
        active[r][c] = False
        row_removed[r] += 1
        col_removed[c] += 1
        removed += 1
    return active


# ---------------------------------------------------------------------------
# Connected components of the active mask
# ---------------------------------------------------------------------------

def find_components(rows, cols, active):
    seen = [[False] * cols for _ in range(rows)]
    comps = []
    for r in range(rows):
        for c in range(cols):
            if not active[r][c] or seen[r][c]:
                continue
            stack = [(r, c)]
            seen[r][c] = True
            comp = []
            while stack:
                cr, cc = stack.pop()
                comp.append((cr, cc))
                for dr, dc, _, _ in DIRS:
                    nr, nc = cr + dr, cc + dc
                    if 0 <= nr < rows and 0 <= nc < cols and active[nr][nc] and not seen[nr][nc]:
                        seen[nr][nc] = True
                        stack.append((nr, nc))
            comps.append(comp)
    return comps


# ---------------------------------------------------------------------------
# Neighbor ordering strategies (gives each pattern a distinct visual identity)
# ---------------------------------------------------------------------------

def ordered_dirs(pattern, r, c, last_dir, rng, rows, cols):
    dirs = list(DIRS)
    if pattern == "winding":
        rng.shuffle(dirs)
    elif pattern == "hLanes":
        dirs.sort(key=lambda d: (0 if d[1] != 0 else 1) + rng.random() * 0.3)
    elif pattern == "zigzag":
        if last_dir is not None:
            dirs.sort(key=lambda d: 0 if (d[0], d[1]) == last_dir else 1 + rng.random())
        else:
            rng.shuffle(dirs)
    elif pattern == "spiral":
        order = [RIGHT, DOWN, LEFT, UP]
        idx = (r + c) % 4
        order = order[idx:] + order[:idx]
        dirs.sort(key=lambda d: order.index(d[2]) + rng.random() * 0.2)
    elif pattern in ("concentric", "ring"):
        ring = min(r, c, rows - 1 - r, cols - 1 - c)

        def ring_of(d):
            nr, nc = r + d[0], c + d[1]
            if 0 <= nr < rows and 0 <= nc < cols:
                return min(nr, nc, rows - 1 - nr, cols - 1 - nc)
            return -99
        dirs.sort(key=lambda d: (abs(ring_of(d) - ring), rng.random()))
    elif pattern == "diagonal":
        pref = [RIGHT, DOWN] if (r + c) % 2 == 0 else [LEFT, UP]
        dirs.sort(key=lambda d: (0 if d[2] in pref else 1) + rng.random() * 0.3)
    elif pattern == "checkerboard":
        pref = [DOWN, RIGHT] if (r % 2 == c % 2) else [UP, LEFT]
        dirs.sort(key=lambda d: (0 if d[2] in pref else 1) + rng.random() * 0.3)
    elif pattern == "staircase":
        pref = [RIGHT, DOWN, LEFT, UP] if r % 2 == 0 else [DOWN, RIGHT, UP, LEFT]
        dirs.sort(key=lambda d: (0 if d[2] in pref[:2] else 1) + pref.index(d[2]) * 0.05 + rng.random() * 0.25)
    elif pattern == "pinwheel":
        cr, cc = (rows - 1) / 2.0, (cols - 1) / 2.0
        ang = math.atan2(r - cr, c - cc)
        quad = int(((ang + math.pi) / (math.pi / 2)) % 4)
        order = [[RIGHT, DOWN, LEFT, UP], [DOWN, LEFT, UP, RIGHT],
                 [LEFT, UP, RIGHT, DOWN], [UP, RIGHT, DOWN, LEFT]][quad]
        dirs.sort(key=lambda d: order.index(d[2]) + rng.random() * 0.2)
    elif pattern == "waves":
        wave = math.sin(c * 0.9)
        pref = [DOWN, RIGHT] if wave >= 0 else [UP, RIGHT]
        dirs.sort(key=lambda d: (0 if d[2] in pref else 1) + rng.random() * 0.3)
    elif pattern == "herringbone":
        block = (r // 1 + c) % 4
        pref = [RIGHT, UP] if block < 2 else [DOWN, LEFT]
        dirs.sort(key=lambda d: (0 if d[2] in pref else 1) + rng.random() * 0.3)
    elif pattern == "cross":
        cr, cc = round((rows - 1) / 2.0), round((cols - 1) / 2.0)
        pref = [DOWN, RIGHT] if abs(r - cr) > abs(c - cc) else [RIGHT, DOWN]
        dirs.sort(key=lambda d: (0 if d[2] in pref else 1) + rng.random() * 0.3)
    else:  # gridLoops, braid, denseMaze -> used mainly with Prim's, order barely matters
        rng.shuffle(dirs)
    return dirs


USE_PRIM = {"gridLoops", "braid", "denseMaze"}

# ---------------------------------------------------------------------------
# Spanning-tree carving over one connected component
# ---------------------------------------------------------------------------

def carve_dfs(comp_set, conn, pattern, rng, rows, cols):
    start = next(iter(comp_set))
    visited = {start}
    stack = [start]
    last_dir_map = {}
    while stack:
        r, c = stack[-1]
        last_dir = last_dir_map.get((r, c))
        moved = False
        for dr, dc, bit, obit in ordered_dirs(pattern, r, c, last_dir, rng, rows, cols):
            nr, nc = r + dr, c + dc
            if (nr, nc) in comp_set and (nr, nc) not in visited:
                conn[r][c] |= bit
                conn[nr][nc] |= obit
                visited.add((nr, nc))
                last_dir_map[(nr, nc)] = (dr, dc)
                stack.append((nr, nc))
                moved = True
                break
        if not moved:
            stack.pop()


def carve_prim(comp_set, conn, rng):
    start = next(iter(comp_set))
    in_tree = {start}
    frontier = []

    def add_frontier(cell):
        r, c = cell
        for dr, dc, bit, obit in DIRS:
            nb = (r + dr, c + dc)
            if nb in comp_set and nb not in in_tree:
                frontier.append((cell, (dr, dc, bit, obit), nb))
    add_frontier(start)
    while frontier:
        idx = rng.randrange(len(frontier))
        cell, (dr, dc, bit, obit), nb = frontier.pop(idx)
        if nb in in_tree:
            continue
        r, c = cell
        nr, nc = nb
        conn[r][c] |= bit
        conn[nr][nc] |= obit
        in_tree.add(nb)
        add_frontier(nb)


def add_extra_edges(comp_set, conn, rng, prob, exempt):
    """Thicken the tree into a braid — never touching an exempt (start/end) cell,
    so its degree stays at exactly 1."""
    for (r, c) in comp_set:
        if (r, c) in exempt:
            continue
        for dr, dc, bit, obit in DIRS:
            if bit in (DOWN, RIGHT):
                nr, nc = r + dr, c + dc
                if (nr, nc) in comp_set and (nr, nc) not in exempt:
                    if not (conn[r][c] & bit) and rng.random() < prob:
                        conn[r][c] |= bit
                        conn[nr][nc] |= obit


def fix_dead_ends(comp_set, conn, rng, rows, cols, active, exempt):
    """Repeatedly: any non-exempt active cell with degree 1 gets an extra edge
    to a neighbor. If none is available (without touching an exempt cell),
    it's excised entirely. Exempt cells (start/end) are never touched, and
    are never used as a target to fix another cell's degree."""
    changed = True
    active_set = set(comp_set)
    while changed:
        changed = False
        for (r, c) in list(active_set):
            if (r, c) in exempt:
                continue
            deg = popcount(conn[r][c])
            if deg != 1:
                continue
            candidates = []
            for dr, dc, bit, obit in DIRS:
                if conn[r][c] & bit:
                    continue
                nr, nc = r + dr, c + dc
                if (nr, nc) in active_set and (nr, nc) not in exempt and not (conn[nr][nc] & obit):
                    candidates.append((dr, dc, bit, obit, nr, nc))
            if candidates:
                dr, dc, bit, obit, nr, nc = candidates[rng.randrange(len(candidates))]
                conn[r][c] |= bit
                conn[nr][nc] |= obit
                changed = True
                continue
            # No safe fix — would we have to touch an exempt cell to excise?
            old = conn[r][c]
            touches_exempt = False
            for dr, dc, bit, obit in DIRS:
                if old & bit:
                    nr, nc = r + dr, c + dc
                    if (nr, nc) in exempt:
                        touches_exempt = True
            if touches_exempt:
                continue  # leave it — outer validation will catch & retry
            conn[r][c] = 0
            for dr, dc, bit, obit in DIRS:
                if old & bit:
                    nr, nc = r + dr, c + dc
                    conn[nr][nc] &= ~obit
            active_set.discard((r, c))
            active[r][c] = False
            changed = True
    return active_set


# ---------------------------------------------------------------------------
# Tree-diameter endpoints -> chosen as the start / end dead ends
# ---------------------------------------------------------------------------

def bfs_farthest(comp_set, conn, start):
    dist = {start: 0}
    q = deque([start])
    far = start
    while q:
        cur = q.popleft()
        if dist[cur] > dist[far]:
            far = cur
        r, c = cur
        for dr, dc, bit, obit in DIRS:
            if conn[r][c] & bit:
                nb = (r + dr, c + dc)
                if nb in comp_set and nb not in dist:
                    dist[nb] = dist[cur] + 1
                    q.append(nb)
    return far


def tree_diameter_endpoints(comp_set, conn):
    start = next(iter(comp_set))
    a = bfs_farthest(comp_set, conn, start)
    b = bfs_farthest(comp_set, conn, a)
    return a, b


# ---------------------------------------------------------------------------
# Full solution generator for one level — single connected network with
# exactly two dead ends: start & end.
# ---------------------------------------------------------------------------

def generate_solution(rows, cols, active, pattern, rng, loop_density):
    comps = find_components(rows, cols, active)
    comps = [c for c in comps if len(c) >= 4]
    if not comps:
        return None, None, None
    comps.sort(key=len, reverse=True)
    main_comp = comps[0]
    for comp in comps[1:]:
        for (r, c) in comp:
            active[r][c] = False
    for r in range(rows):
        for c in range(cols):
            if active[r][c] and (r, c) not in main_comp:
                active[r][c] = False

    comp_set = set(main_comp)
    conn = [[0] * cols for _ in range(rows)]
    if pattern in USE_PRIM:
        carve_prim(comp_set, conn, rng)
    else:
        carve_dfs(comp_set, conn, pattern, rng, rows, cols)

    a, b = tree_diameter_endpoints(comp_set, conn)
    exempt = {a, b}
    add_extra_edges(comp_set, conn, rng, loop_density, exempt)
    fix_dead_ends(comp_set, conn, rng, rows, cols, active, exempt)
    return conn, a, b


def validate_solution(rows, cols, conn, active, a, b):
    active_cells = [(r, c) for r in range(rows) for c in range(cols)
                    if active[r][c] and conn[r][c] > 0]
    if len(active_cells) < 4:
        return False
    deg1 = [cell for cell in active_cells if popcount(conn[cell[0]][cell[1]]) == 1]
    if set(deg1) != {a, b}:
        return False
    comp_set = set(active_cells)
    seen = {active_cells[0]}
    stack = [active_cells[0]]
    while stack:
        r, c = stack.pop()
        for dr, dc, bit, obit in DIRS:
            if conn[r][c] & bit:
                nb = (r + dr, c + dc)
                if nb in comp_set and nb not in seen:
                    seen.add(nb)
                    stack.append(nb)
    if len(seen) != len(comp_set):
        return False
    for r in range(rows):
        if not any(active[r][c] for c in range(cols)):
            return False
    for c in range(cols):
        if not any(active[r][c] for r in range(rows)):
            return False
    return True


# ---------------------------------------------------------------------------
# Scrambling
# ---------------------------------------------------------------------------

def is_symmetric(v):
    t = rotate90(v)
    for _ in range(3):
        if t != v:
            return False
        t = rotate90(t)
    return True


def scramble(rows, cols, conn, active, min_rot, max_rot, rng):
    cells = [[-1] * cols for _ in range(rows)]
    solution = [[-1] * cols for _ in range(rows)]
    for r in range(rows):
        for c in range(cols):
            if not active[r][c] or conn[r][c] == 0:
                continue
            orig = conn[r][c]
            solution[r][c] = orig
            sym = is_symmetric(orig)
            k = rng.randint(min_rot, max_rot)
            v = orig
            for _ in range(k):
                v = rotate90(v)
            if not sym:
                safety = 0
                while v == orig and safety < 4:
                    v = rotate90(v)
                    safety += 1
            cells[r][c] = v
    return cells, solution


# ---------------------------------------------------------------------------
# Difficulty curve — grid size ramps 4x4 (level 1) up to 8x8 (level 500)
# ---------------------------------------------------------------------------

TOTAL = 500
EASY_END = 175
MED_END = 375


def lerp(a, b, t):
    return a + (b - a) * t


def difficulty_for_level(level):
    if level <= EASY_END:
        t = (level - 1) / max(EASY_END - 1, 1)
        phase = "easy"
        size = round(lerp(4, 5, t))
        mask_pct = lerp(0.0, 0.10, t)
        min_rot, max_rot = 1, 3
        loop_density = lerp(0.05, 0.12, t)
    elif level <= MED_END:
        t = (level - EASY_END - 1) / max(MED_END - EASY_END - 1, 1)
        phase = "medium"
        size = round(lerp(5, 7, t))
        mask_pct = lerp(0.14, 0.26, t)
        min_rot, max_rot = 1, 4
        loop_density = lerp(0.14, 0.22, t)
    else:
        t = (level - MED_END - 1) / max(TOTAL - MED_END - 1, 1)
        phase = "hard"
        size = round(lerp(7, 8, t))
        mask_pct = lerp(0.26, 0.36, t)
        min_rot, max_rot = 2, 4
        loop_density = lerp(0.22, 0.32, t)
    return phase, size, mask_pct, min_rot, max_rot, loop_density


def pattern_for_level(level):
    idx = (level - 1) % len(PATTERNS)
    shift = ((level - 1) // len(PATTERNS)) % len(PATTERNS)
    return PATTERNS[(idx + shift) % len(PATTERNS)]


# ---------------------------------------------------------------------------
# Level building with automatic retry to guarantee a valid, unique result
# ---------------------------------------------------------------------------

def build_level(level, seed_salt=0):
    phase, size, mask_pct, min_rot, max_rot, loop_density = difficulty_for_level(level)
    pattern = pattern_for_level(level)

    for attempt in range(60):
        rng = random.Random(level * 1000003 + attempt * 97 + 13 + seed_salt * 7919)
        rows = size
        cols = size
        if size >= 5:
            skew = rng.choice([-1, 0, 0, 0, 1])
            cols = max(4, min(8, size + skew))
        rows = min(8, max(4, rows))
        cols = min(8, max(4, cols))

        this_mask_pct = mask_pct * (0.9 ** (attempt // 10))
        this_loop_density = loop_density * (0.92 ** (attempt // 10))

        active = build_mask(rows, cols, this_mask_pct, rng, pattern)
        total_cells = rows * cols
        if sum(row.count(True) for row in active) < max(8, int(total_cells * 0.55)):
            this_mask_pct *= 0.5
            active = build_mask(rows, cols, this_mask_pct, rng, pattern)

        conn, a, b = generate_solution(rows, cols, active, pattern, rng, this_loop_density)
        if conn is None:
            continue
        if not validate_solution(rows, cols, conn, active, a, b):
            continue

        active_count = sum(1 for r in range(rows) for c in range(cols)
                            if active[r][c] and conn[r][c] > 0)
        if active_count < max(4, int(rows * cols * 0.35)):
            continue

        cells, solution = scramble(rows, cols, conn, active, min_rot, max_rot, rng)
        return {
            "level": level,
            "phase": phase,
            "pattern": pattern,
            "rows": rows,
            "cols": cols,
            "start": [a[0], a[1]],
            "end": [b[0], b[1]],
            "cells": cells,
            "solution": solution,
        }
    raise RuntimeError(f"Failed to build level {level} after retries")


def main():
    levels = []
    seen_layouts = set()
    for lvl in range(1, TOTAL + 1):
        data = build_level(lvl)
        key = (data["rows"], data["cols"], tuple(tuple(row) for row in data["solution"]))
        tries = 0
        while key in seen_layouts and tries < 40:
            # extremely rare duplicate -> rebuild with a different salt
            data = build_level(lvl, seed_salt=tries + 1)
            key = (data["rows"], data["cols"], tuple(tuple(row) for row in data["solution"]))
            tries += 1
        if key in seen_layouts:
            raise RuntimeError(f"Could not de-duplicate level {lvl}")
        seen_layouts.add(key)
        levels.append(data)
    with open("C:\\SUBHADIP MANNA\\Godot\\ThinkinfinityPhase2\\tools\\levels.json", "w") as f:
        json.dump({"levels": levels}, f)
    print("done", len(levels))


if __name__ == "__main__":
    main()
 