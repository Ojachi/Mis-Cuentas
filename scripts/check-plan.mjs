import { existsSync, readFileSync } from 'node:fs';
import { dirname, extname, resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const read = (path) => readFileSync(resolve(root, path), 'utf8');
const fail = (message) => {
  throw new Error(`Plan check failed: ${message}`);
};

const tasks = read('openspec/changes/hot-dog-finance-mvp/tasks.md');
const design = read('openspec/changes/hot-dog-finance-mvp/design.md');
const planDirectory = 'openspec/changes/hot-dog-finance-mvp';
const documentPaths = [
  'proposal.md',
  'design.md',
  'exploration.md',
  'tasks.md',
  'specs/business-access/spec.md',
  'specs/financial-records/spec.md',
  'specs/offline-financial-sync/spec.md',
  'specs/financial-reporting-exchange/spec.md',
].map((path) => `${planDirectory}/${path}`);
const documents = new Map(
  documentPaths.map((path) => [resolve(root, path), read(path)]),
);
const specs = documentPaths
  .filter((path) => path.includes('/specs/'))
  .map((path) => documents.get(resolve(root, path)));

const slug = (heading) =>
  heading
    .toLowerCase()
    .replace(/[^\w -]/g, '')
    .trim()
    .replace(/\s+/g, '-');
const withoutFencedCode = (text) => text.replace(/^```[\s\S]*?^```$/gm, '');
const anchors = (path) => {
  const text = readFileSync(path, 'utf8');
  if (extname(path) === '.md') {
    return new Set(
      [...text.matchAll(/^#+ (.+)$/gm)].map((match) => slug(match[1])),
    );
  }
  return new Set(
    [...text.matchAll(/\bid=["']([^"']+)["']/g)].map((match) => match[1]),
  );
};

let localLinks = 0;
for (const [sourcePath, source] of documents) {
  for (const match of withoutFencedCode(source).matchAll(
    /\[[^\]]*\]\(([^)\s]+)(?:\s+[^)]*)?\)/g,
  )) {
    const destination = match[1];
    if (/^[a-z][a-z\d+.-]*:/i.test(destination)) continue;
    const [relativePath, fragment] = destination.split('#', 2);
    const targetPath = resolve(dirname(sourcePath), relativePath || '.');
    if (!existsSync(targetPath))
      fail(`missing link target ${destination} in ${sourcePath}`);
    localLinks += 1;
    if (fragment) {
      const targetAnchors = anchors(targetPath);
      if (!targetAnchors.has(decodeURIComponent(fragment))) {
        fail(`missing anchor ${destination} in ${sourcePath}`);
      }
    }
  }
}

const markers = [...tasks.matchAll(/^- \[[ x]\] \*\*(P0|T\d+\.\d+) —/gm)];
const entries = markers.map((marker, index) => [
  marker[1],
  tasks.slice(marker.index, markers[index + 1]?.index),
]);
if (entries.length !== 24)
  fail(`expected 24 task entries, found ${entries.length}`);

const taskBodies = new Map(entries);
for (const [id, body] of taskBodies) {
  for (const label of [
    'Depends:',
    'Decisions:',
    'Surface:',
    'Spec:',
    'Accept:',
    'Check:',
    'Expected:',
    'Rollback:',
  ]) {
    if (!body.includes(label)) fail(`${id} is missing ${label}`);
  }
}

const dependencies = new Map(
  [...taskBodies].map(([id, body]) => {
    const match = body.match(/Depends: (.*?)\. Decisions:/);
    return [
      id,
      match
        ? [...match[1].matchAll(/P0|T\d+\.\d+/g)].map((item) => item[0])
        : [],
    ];
  }),
);
const visiting = new Set();
const visited = new Set();
const visit = (id) => {
  if (visiting.has(id)) fail(`dependency cycle at ${id}`);
  if (visited.has(id)) return;
  visiting.add(id);
  for (const dependency of dependencies.get(id) ?? []) {
    if (!taskBodies.has(dependency))
      fail(`${id} depends on missing ${dependency}`);
    visit(dependency);
  }
  visiting.delete(id);
  visited.add(id);
};
for (const id of taskBodies.keys()) visit(id);

const decisions = new Map(
  [
    ...design.matchAll(/^\| (D\d{2}) \|.*?\| (APPROVED|OPEN) \| (.*?) \|/gm),
  ].map((entry) => [
    entry[1],
    {
      status: entry[2],
      tasks: [...entry[3].matchAll(/T\d+\.\d+/g)].map((item) => item[0]),
    },
  ]),
);
if (decisions.size !== 9) fail(`expected 9 decisions, found ${decisions.size}`);
if (decisions.get('D01')?.status !== 'APPROVED') fail('D01 must be APPROVED');
for (const [decision, details] of decisions) {
  const gated = [...taskBodies].flatMap(([id, body]) => {
    const gate = body.match(/Decisions: ([^.]+)\./)?.[1] ?? '';
    return !gate.startsWith('none') && gate.includes(decision) ? [id] : [];
  });
  if (gated.join(',') !== details.tasks.join(','))
    fail(`${decision} task gate mismatch`);
}

const headings = specs.flatMap((spec) => [
  ...spec.matchAll(/^### Requirement: (.+)$/gm),
  ...spec.matchAll(/^#### Scenario: (.+)$/gm),
]);
for (const heading of headings) {
  if (!tasks.includes(heading[1]))
    fail(`missing scenario coverage: ${heading[1]}`);
}

console.log(
  `PASS plan: ${localLinks} local links, ${taskBodies.size} tasks, ${decisions.size} decisions, ${headings.length} requirements/scenarios, acyclic dependencies.`,
);
