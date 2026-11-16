import { spawnSync } from 'node:child_process';
import { readFile, writeFile, mkdir, copyFile, cp } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const platform = process.argv[2] || (process.platform === 'win32' ? 'windows' : 'linux');
if (!['windows', 'linux'].includes(platform)) throw new Error('Usage: node build.mjs [windows|linux]');
if ((platform === 'windows') !== (process.platform === 'win32')) throw new Error('Build on the matching Windows or Linux host.');
function run(command, args, cwd = root) {
  const result = spawnSync(command, args, { cwd, stdio: 'inherit' });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`${command} failed (${result.status})`);
}
// Lime generates the normal OpenFL bootstrap and assets. Its application packager
// expects an EXE, so compile and package the shared library with hxcpp directly.
run('haxelib', ['run', 'lime', 'update', platform, '-64']);
run('haxe', [`Export/${platform}/haxe/release.hxml`]);
const output = join(root, 'Export', platform);
const libraryName = platform === 'windows' ? 'CHAOSRUNTIME' : 'libCHAOSRUNTIME';
run('haxelib', ['run', 'hxcpp', 'Build.xml', '-DHXCPP_M64', `-D${platform}`, '-Ddll_link', `-DHAXE_OUTPUT_FILE=${libraryName}`], join(output, 'obj'));
const bin = join(output, 'bin');
await mkdir(bin, { recursive: true });
const binary = platform === 'windows' ? 'CHAOSRUNTIME.dll' : 'libCHAOSRUNTIME.so';
// hxcpp's Linux shared-library linker uses .dso; distribute the standard .so name.
await copyFile(join(output, 'obj', platform === 'windows' ? binary : `${libraryName}.dso`), join(bin, binary));
const paths = spawnSync('haxelib', ['path', 'lime'], { cwd: root, encoding: 'utf8' });
if (paths.status !== 0) throw new Error('Cannot resolve the installed Lime dependency.');
const limeSrc = paths.stdout.split(/\r?\n/).find(line => line.trim() && !line.startsWith('-') && !line.startsWith('Warning:'))?.trim();
if (!limeSrc) throw new Error('Cannot find Lime sources.');
await copyFile(join(limeSrc, '..', 'ndll', platform === 'windows' ? 'Windows64' : 'Linux64', 'lime.ndll'), join(bin, 'lime.ndll'));
await cp(join(root, 'include'), join(bin, 'include'), { recursive: true });
await cp(join(root, 'examples'), join(bin, 'examples'), { recursive: true });
await copyFile(join(root, 'README.md'), join(bin, 'README.md'));
const manifest = JSON.parse(await readFile(join(root, 'manifest.json'), 'utf8'));
Object.assign(manifest, { kind: 'dll', binary, requiredFiles: [binary, 'lime.ndll', 'include/chaos_runtime.h', 'examples/main.cpp', 'README.md'] });
if (platform === 'windows') {
  await copyFile(join(output, 'obj', 'obj', 'lib', 'CHAOSRUNTIME.lib'), join(bin, 'CHAOSRUNTIME.lib'));
  manifest.requiredFiles.push('CHAOSRUNTIME.lib');
}
await writeFile(join(bin, 'manifest.json'), JSON.stringify(manifest, null, 2) + '\n');
console.log(`Built C++ developer library: ${bin}`);
