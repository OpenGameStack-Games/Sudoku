import argparse
import json
import random
import sys
import copy

def empty_board():
    return [[0]*9 for _ in range(9)]

def is_valid(board, r, c, val):
    for i in range(9):
        if board[r][i] == val:
            return False
        if board[i][c] == val:
            return False
    br = (r // 3) * 3
    bc = (c // 3) * 3
    for i in range(3):
        for j in range(3):
            if board[br+i][bc+j] == val:
                return False
    return True

def solve(board, count_only=False, max_count=2):
    def find_empty():
        for i in range(9):
            for j in range(9):
                if board[i][j] == 0:
                    return (i, j)
        return None

    def backtrack(count):
        empty = find_empty()
        if not empty:
            return count + 1
        r, c = empty
        for val in range(1, 10):
            if is_valid(board, r, c, val):
                board[r][c] = val
                count = backtrack(count)
                board[r][c] = 0
                if count >= max_count:
                    return count
        return count

    return backtrack(0)

def generate_full_board():
    board = empty_board()
    def fill():
        empty = None
        for i in range(9):
            for j in range(9):
                if board[i][j] == 0:
                    empty = (i, j)
                    break
            if empty: break
        if not empty:
            return True
        r, c = empty
        vals = list(range(1, 10))
        random.shuffle(vals)
        for val in vals:
            if is_valid(board, r, c, val):
                board[r][c] = val
                if fill():
                    return True
                board[r][c] = 0
        return False
    fill()
    return board

def remove_cells_with_symmetry(board, target_clues):
    # Clue count starts at 81
    clues = 81
    cells = []
    for r in range(9):
        for c in range(9):
            if r * 9 + c <= (8 - r) * 9 + (8 - c):
                cells.append((r, c))
    random.shuffle(cells)

    for r, c in cells:
        if clues <= target_clues:
            break
        
        sym_r, sym_c = 8 - r, 8 - c
        
        # Save original values
        v1, v2 = board[r][c], board[sym_r][sym_c]
        
        # Remove them
        board[r][c] = 0
        board[sym_r][sym_c] = 0
        
        if solve(copy.deepcopy(board), max_count=2) == 1:
            if r == sym_r and c == sym_c:
                clues -= 1
            else:
                clues -= 2
        else:
            # Revert
            board[r][c] = v1
            board[sym_r][sym_c] = v2

    return board

def board_to_string(board):
    return "".join(str(board[r][c]) for r in range(9) for c in range(9))

def generate_puzzles(count, target_clues):
    puzzles = []
    while len(puzzles) < count:
        board = generate_full_board()
        board = remove_cells_with_symmetry(board, target_clues)
        puzzles.append(board_to_string(board))
        print(f"Generated puzzle {len(puzzles)}/{count}")
    return puzzles

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Sudoku Puzzles")
    parser.add_argument("--count", type=int, default=10, help="Count of puzzles per difficulty")
    parser.add_argument("--out", type=str, default="game/data/puzzles.json", help="Output JSON path")
    args = parser.parse_args()

    print("Generating Easy puzzles...")
    easy = generate_puzzles(args.count, 50)
    print("Generating Medium puzzles...")
    medium = generate_puzzles(args.count, 40)
    print("Generating Hard puzzles...")
    hard = generate_puzzles(args.count, 30)

    dataset = {
        "easy": easy,
        "medium": medium,
        "hard": hard
    }
    
    import os
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w") as f:
        json.dump(dataset, f, indent=4)
    print(f"Exported dataset to {args.out}")
