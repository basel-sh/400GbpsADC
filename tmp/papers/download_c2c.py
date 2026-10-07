exec(open('tmp/papers/inventory_c2c.py').read().split('for u in urls:')[0])
import concurrent.futures,numpy as np
u=urls[0];names=[n for n in zipfile.ZipFile(R(u)).namelist() if n.endswith('_thru.s4p') or '14dB_fext' in n]
out=pathlib.Path('channel/data/c2c_candidates');out.mkdir(parents=True,exist_ok=True)
def work(n):
 data=zipfile.ZipFile(R(u)).read(n);(out/n).write_bytes(data);return n
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as ex:
 for n in ex.map(work,names):print(n,flush=True)
