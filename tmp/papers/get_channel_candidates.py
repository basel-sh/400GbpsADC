exec(open('tmp/papers/list_remote_zip.py').read().split('z=zipfile.ZipFile(Remote())')[0])
z=zipfile.ZipFile(Remote());out=pathlib.Path('channel/data/ieee_candidates');out.mkdir(parents=True,exist_ok=True)
for name in ['Readme.txt','Bch1_3p5_t.s4p','Bch2_7_t.s4p','Bch2_7_f1.s4p','Bch3_14_t.s4p']:
    data=z.read(name);(out/name).write_bytes(data);print(name,len(data),flush=True)
