import re
import os

SCRIPTS_DIR = os.path.dirname(__file__)

def map_extends(ext):
    mapping = {
        'Node2D': 'Node2D',
        'Control': 'Control',
        'Node': 'Node',
        'TileMap': 'TileMap',
        'Resource': 'Resource',
        'Sprite2D': 'Sprite2D',
        'Area2D': 'Area2D'
    }
    return mapping.get(ext, 'Node')


def sanitize(name):
    return re.sub(r"[^0-9A-Za-z_]", "", name)


def parse_gd(path):
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()
    class_name = None
    extends = 'Node'
    signals = []
    funcs = []

    m = re.search(r'^class_name\s+(\w+)', text, re.MULTILINE)
    if m:
        class_name = m.group(1).strip()

    m = re.search(r'^extends\s+([A-Za-z0-9_]+)', text, re.MULTILINE)
    if m:
        extends = m.group(1).strip()

    for sm in re.finditer(r'^signal\s+([a-zA-Z0-9_]+)\s*(\(([^)]*)\))?', text, re.MULTILINE):
        name = sm.group(1)
        params = sm.group(3) or ''
        params = [p.strip() for p in params.split(',') if p.strip()]
        signals.append((name, params))

    for fm in re.finditer(r'^func\s+([a-zA-Z0-9_]+)\s*\(([^)]*)\)\s*(->\s*([^:\n]+))?', text, re.MULTILINE):
        name = fm.group(1)
        params = fm.group(2) or ''
        params = [p.strip() for p in params.split(',') if p.strip()]
        ret = fm.group(4) or None
        funcs.append((name, params, ret))

    return class_name, extends, signals, funcs


def gen_cs_for(path):
    class_name, extends, signals, funcs = parse_gd(path)
    base = map_extends(extends)
    if not class_name:
        class_name = os.path.splitext(os.path.basename(path))[0].capitalize()
    cs_name = os.path.splitext(path)[0] + '.cs'
    if os.path.exists(cs_name):
        print(f"Skipping existing: {cs_name}")
        return

    lines = []
    lines.append('using Godot;')
    lines.append('using System;')
    lines.append('')
    lines.append(f'public partial class {class_name} : {base}')
    lines.append('{')

    # Signals
    for sig, params in signals:
        # create delegate with object parameters
        if params:
            lines.append(f'    [Signal]')
            lines.append(f'    public delegate void {sig}({", ".join(["object p"+str(i) for i in range(len(params))])});')
        else:
            lines.append(f'    [Signal]')
            lines.append(f'    public delegate void {sig}();')
        lines.append('')

    # _Ready/_Process/_PhysicsProcess
    has_ready = any(f[0] == '_ready' for f in funcs)
    has_process = any(f[0] == '_process' for f in funcs)
    has_physics = any(f[0] == '_physics_process' for f in funcs)

    if has_ready:
        lines.append('    public override void _Ready()')
        lines.append('    {')
        lines.append('        // Ported stub for _ready')
        lines.append('    }')
        lines.append('')

    if has_process:
        lines.append('    public override void _Process(double delta)')
        lines.append('    {')
        lines.append('        // Ported stub for _process')
        lines.append('    }')
        lines.append('')

    if has_physics:
        lines.append('    public override void _PhysicsProcess(double delta)')
        lines.append('    {')
        lines.append('        // Ported stub for _physics_process')
        lines.append('    }')
        lines.append('')

    # Other funcs
    for name, params, ret in funcs:
        if name in ['_ready','_process','_physics_process']:
            continue
        # create method with matching parameter count
        param_list = []
        for i,p in enumerate(params):
            # strip default values and types
            pname = re.split(':|=', p)[0].strip()
            if not pname:
                pname = 'p'+str(i)
            param_list.append(f'object {sanitize(pname)} = null')
        params_sig = ', '.join(param_list)
        if ret is None:
            lines.append(f'    public void {name}({params_sig})')
            lines.append('    {')
            lines.append('        // Ported stub')
            lines.append('    }')
            lines.append('')
        else:
            lines.append(f'    public object {name}({params_sig})')
            lines.append('    {')
            lines.append('        // Ported stub (returns null)')
            lines.append('        return null;')
            lines.append('    }')
            lines.append('')

    lines.append('}')

    with open(cs_name, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    print(f'Generated {cs_name}')


if __name__ == '__main__':
    for fname in os.listdir(SCRIPTS_DIR):
        if fname.endswith('.gd'):
            gen_cs_for(os.path.join(SCRIPTS_DIR, fname))
    print('Generation complete')
