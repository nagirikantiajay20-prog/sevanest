import re,subprocess,sys
def sh(*a): return subprocess.run(a,capture_output=True,text=True,encoding='utf8').stdout
old_c,new_c=sys.argv[1],sys.argv[2]
tok=sh('git','show',f'{new_c}:lib/app/theme/tokens.dart')
tokold=sh('git','show',f'{old_c}:lib/app/theme/tokens.dart')
m={}
for src in (tokold,tok):
    for n,v in re.findall(r'static const (\w+)\s*=\s*Color\(\s*(0x[0-9A-Fa-f]{8})\s*,?\s*\)',src): m[n]=v.upper().replace('0X','#')
def norm(s):
    s=re.sub(r'import [^;]*;','',s)
    s=re.sub(r'AppColors\.(\w+)',lambda x:m.get(x.group(1),x.group(0)),s)
    s=re.sub(r'\bColors\.white\b(?!\d)','#FFFFFFFF',s)
    s=re.sub(r'Color\(\s*(0x[0-9A-Fa-f]{8})\s*,?\s*\)',lambda x:x.group(1).upper().replace('0X','#'),s)
    s=re.sub(r'//[^\n]*','',s)
    s=re.sub(r'\bconst\b','',s)
    s=re.sub(r'\s+','',s)
    s=re.sub(r',([)\]}])',r'\1',s)
    return s
files=sh('git','diff','--name-only',old_c,new_c,'--','lib').split()
import difflib
for f in files:
    if f.endswith('tokens.dart') or '/gen/' in f or f.endswith('.arb'): continue
    a=sh('git','show',f'{old_c}:{f}'); b=sh('git','show',f'{new_c}:{f}')
    if not a or not b: print('NEW/DEL',f); continue
    na,nb=norm(a),norm(b)
    if na==nb: print('IDENTICAL',f); continue
    sm=difflib.SequenceMatcher(None,na,nb,autojunk=False)
    ops=[o for o in sm.get_opcodes() if o[0]!='equal']
    print('DIFF',f,len(ops))
    for tag,i1,i2,j1,j2 in ops[:6]:
        print('   ',tag,repr(na[max(0,i1-30):i2+30][:140]),'=>',repr(nb[max(0,j1-30):j2+30][:140]))
