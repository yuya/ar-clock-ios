#!/usr/bin/env python3
"""Web のシェーダ（WebGL の GLSL）を Metal のシェーダ言語に機械的に直す。

  GLSL (WebGL1) --書き換え--> GLSL 4.5 --glslang--> SPIR-V --SPIRV-Cross--> Metal --metal--> コンパイル確認

人が書き直すのではなく道具で変換するので、Web 側のシェーダを変えたら、同じ手順でそのまま作り直せる。
"""
import json, os, re, subprocess, sys

OUT = sys.argv[1] if len(sys.argv) > 1 else 'Generated/Shaders'
os.makedirs(OUT, exist_ok=True)
shaders = json.loads(subprocess.check_output(['node', 'scripts/extract-shaders.js', 'Web/index.html']))

def to_glsl450(src):
    # 精度指定の前置きを外す
    src = re.sub(r'#ifdef GL_FRAGMENT_PRECISION_HIGH.*?#endif\n', '', src, flags=re.S)
    src = re.sub(r'^\s*precision\s+\w+\s+float\s*;\s*$', '', src, flags=re.M)
    floats, samplers = [], []
    def grab(m):
        ty, names = m.group(1), [n.strip() for n in m.group(2).split(',')]
        (samplers if ty.startswith('sampler') else floats).extend((ty, n) for n in names)
        return ''
    src = re.sub(r'\buniform\s+(\w+)\s+([^;]+);', grab, src)
    head = '#version 450\nlayout(location=0) out vec4 fragColor;\n'
    if floats:
        head += 'layout(std140, set=0, binding=0) uniform Params {\n' + ''.join(f'  {t} {n};\n' for t, n in floats) + '};\n'
    for i, (t, n) in enumerate(samplers):
        head += f'layout(set=0, binding={i + 1}) uniform {t} {n};\n'
    src = src.replace('texture2D(', 'texture(').replace('gl_FragColor', 'fragColor')
    return head + src, floats, samplers

def run(cmd):
    p = subprocess.run(cmd, capture_output=True, text=True)
    return p.returncode, (p.stdout + p.stderr).strip()

ok = True
report = []
for name, src in shaders.items():
    glsl, floats, samplers = to_glsl450(src)
    base = os.path.join(OUT, name)
    open(base + '.frag', 'w').write(glsl)
    code, log = run(['glslangValidator', '-V', '-S', 'frag', '-o', base + '.spv', base + '.frag'])
    if code:
        ok = False; report.append(f'{name}: GLSL→SPIR-V 失敗\n{log}'); continue
    code, log = run(['spirv-cross', '--msl', '--msl-version', '20100', '--msl-ios', '--output', base + '.metal', base + '.spv'])
    if code:
        ok = False; report.append(f'{name}: SPIR-V→Metal 失敗\n{log}'); continue
    code, log = run(['xcrun', '-sdk', 'iphoneos', 'metal', '-c', base + '.metal', '-o', base + '.air'])
    if code:
        ok = False; report.append(f'{name}: Metal のコンパイル失敗\n{log}'); continue
    lines = len(open(base + '.metal').read().splitlines())
    report.append(f'{name}: OK（値の入力 {len(floats)} 個・画像の入力 {len(samplers)} 個 → Metal {lines} 行）')
    for ext in ('.spv', '.air'):
        os.remove(base + ext)
text = '\n'.join(report)
open(os.path.join(OUT, 'REPORT.txt'), 'w').write(text + '\n')
print(text)
sys.exit(0 if ok else 1)
