from flask import Flask, request, jsonify
import os

app = Flask(__name__)

notes = set()

safe_path = os.path.join(os.getcwd(), "notes")

def is_safe_path(basedir, path, follow_symlinks=True):
    if follow_symlinks:
        matchpath = os.path.realpath(path)
    else:
        matchpath = os.path.abspath(path)
    return basedir == os.path.commonpath((basedir, matchpath))

@app.route('/put_note', methods=['POST'])
def put_note():
    note = request.json
    if type(note) != dict or "name" not in note or "value" not in note:
        return jsonify({"ok": False, "error": "invalid note"})

    name = note["name"]
    value = note["value"]

    # Check if the note already exists
    if name in notes:
        return jsonify({"ok": False, "error": "note already exists"})

    candidate_path = os.path.join(safe_path, name)

    if not is_safe_path(safe_path, candidate_path):
        return jsonify({"ok": False, "error": "invalid note"})
        
    with open(candidate_path, "w") as f:
        f.write(value)
        notes.add(name)

    return jsonify({"ok": True})

@app.route('/get_note', methods=['POST'])
def get_note():
    note = request.json
    if type(note) != dict or "name" not in note:
        return jsonify({"ok": False, "error": "invalid note"})

    name = note["name"]
    if name not in notes:
        return jsonify({"ok": False, "error": "no such note"})

    candidate_path = os.path.join(safe_path, name)

    if not is_safe_path(safe_path, candidate_path):
        return jsonify({"ok": False, "error": "invalid note"})

    with open(candidate_path, "r") as f:
        value = f.read()

    return jsonify({"ok": True, "note": value})
