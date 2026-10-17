"""Explicit live source download of the known command helper, checked against local source."""
import argparse
import asyncio
from datetime import timedelta
import hashlib
import json
from pathlib import Path
import sys

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
from validate_zvm_mcp import content, EXPECTED
from zvm_mcp import device_selector


async def validate(args):
    server=Path(__file__).with_name('zvm_mcp.py').resolve()
    launch=[str(server),'--allow-login','--allow-startup','--allow-commands',
            '--runner-name','ZM537EF1','--allow-downloads','--download-root',str(args.download_root),
            '--credential-file',str(args.credential_file),'--device',args.device]
    if args.reader_name:launch.extend(['--download-runner-name',args.reader_name])
    evidence={'purpose':__doc__}
    def persist():args.output.write_text(json.dumps(evidence,indent=2)+'\n')
    async with stdio_client(StdioServerParameters(command=sys.executable,args=launch,cwd=str(server.parent))) as (reader,writer):
        async with ClientSession(reader,writer,read_timeout_seconds=timedelta(seconds=360)) as client:
            await client.initialize()
            assert {t.name for t in (await client.list_tools()).tools}==EXPECTED
            try:
                for stage,tool,params in [('connect','zvm_connect',{}),
                    ('login','zvm_login',{}),('startup','zvm_startup',{'verify_cms':True}),
                    ('download','zvm_download',{'filename':args.filename,'filetype':args.filetype,'filemode':args.filemode,
                                               'create_runner':args.create_reader,'timeout':300})]:
                    result=content(await client.call_tool(tool,params));evidence[stage]=result;persist()
                    print(json.dumps({'stage':stage,**{k:result.get(k) for k in ('ok','outcome','reader','record_count','byte_count','download_complete')}}),flush=True)
                    if not result['ok']:return evidence
                result=evidence['download']
                actual=Path(result['native_file']).read_bytes()
                if args.expected_native:
                    expected=Path(args.expected_native).read_bytes()
                    evidence['expected_native_sha256']=hashlib.sha256(expected).hexdigest()
                    evidence['downloaded_native_sha256']=hashlib.sha256(actual).hexdigest()
                    evidence['candidate_readback_equal']=actual==expected
                    if actual!=expected:
                        persist()
                        return evidence
                else:
                    expected=b''.join(line.ljust(80).encode('cp037') for line in server.with_name('ZMCPRUN.EXEC').read_text(encoding='ascii').splitlines())
                    assert actual==expected,'Native downloaded helper differs from known local source'
                manifest=json.loads(Path(result['manifest']).read_text())
                assert manifest['cms']['recfm']=='F' and manifest['cms']['lrecl']==80
                assert manifest['sha256']==hashlib.sha256(expected).hexdigest()
                assert manifest['record_lengths']==[80]*(len(expected)//80)
                assert all(step.get('cms_rc',0)==0 for step in manifest['verification'])
                evidence['known_source_verified']=True;persist()
            finally:
                evidence['disconnect']=content(await client.call_tool('zvm_disconnect',{}));persist()
    return evidence


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--live',required=True,action='store_true')
    p.add_argument('--create-reader',action='store_true')
    p.add_argument('--reader-name')
    p.add_argument('--device',type=device_selector,default='0200@')
    p.add_argument('--credential-file',type=Path,required=True)
    p.add_argument('--download-root',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--filename',default='ZM537EF1')
    p.add_argument('--filetype',default='EXEC')
    p.add_argument('--filemode',default='A1')
    p.add_argument('--expected-native',type=Path)
    args=p.parse_args()
    if args.create_reader and args.reader_name:p.error('Select new-reader creation OR existing-reader reuse')
    e=asyncio.run(validate(args))
    passed=(e.get('known_source_verified',False) or e.get('candidate_readback_equal',False)) and e.get('download',{}).get('download_complete',False)
    print(json.dumps({'passed':passed,'disconnect':e.get('disconnect')}),flush=True)
    raise SystemExit(0 if passed else 1)
