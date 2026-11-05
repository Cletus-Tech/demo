const fs = require("node:fs");
const vm = require("node:vm");

const file = "resources/views/dashboard.blade.php";
const html = fs.readFileSync(file, "utf8");
const scripts = [...html.matchAll(/<script\\b([^>]*)>([\\s\\S]*?)<\\/script>/gi)]
  .filter(([, attributes]) => !/\\bsrc\\s*=/.test(attributes))
  .map(([, , source]) => source);

if (scripts.length === 0) {
  throw new Error("No inline dashboard script was found.");
}

scripts.forEach((source, index) => {
  new vm.Script(source, { filename: `dashboard-inline-${index + 1}.js` });
});

process.stdout.write(`Validated ${scripts.length} inline dashboard script(s).\\n`);
