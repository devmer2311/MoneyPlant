import {expect,it} from 'vitest';
import {execFileSync} from 'node:child_process';
import {mkdtempSync,readFileSync,unlinkSync,rmdirSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {parseSections} from '../src/lib/notes';
it('publishes the same authored notes the website consumes',()=>{
 const dir=mkdtempSync(join(tmpdir(),'money-plant-notes-'));
 const file=join(dir,'notes.md');
 try {
  execFileSync(process.execPath,['scripts/release-notes.mjs','v2.0.1',file]);
  const text=readFileSync(file,'utf8');
  expect(parseSections(text).new).toEqual(['Export your ledger as a PDF, with preset dates or a custom date range.']);
  expect(text).not.toContain('Full Changelog');
  expect(()=>execFileSync(process.execPath,['scripts/release-notes.mjs','v99.0.0',file],{stdio:'pipe'})).toThrow();
 }finally{try{unlinkSync(file);}finally{rmdirSync(dir);}}
});
