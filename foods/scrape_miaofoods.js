const fs = require("fs");
const path = require("path");
const vm = require("vm");

const urls = [
  "https://www.miaofoods.com/cate/0DQM1ZK2G6.html",
  "https://www.miaofoods.com/cate/2VFC753X2J.html",
  "https://www.miaofoods.com/cate/NP8Z3NMATH.html",
  "https://www.miaofoods.com/cate/AZ07CSC20I.html",
  "https://www.miaofoods.com/cate/YTJ3BXF4K7.html",
  "https://www.miaofoods.com/cate/TE2R3V4FC3.html",
  "https://www.miaofoods.com/cate/3STTPBRR3I.html",
  "https://www.miaofoods.com/cate/GRH51YS6SJ.html",
  "https://www.miaofoods.com/cate/JSNC9WDKIF.html",
  "https://www.miaofoods.com/cate/DBYCATD8RM.html",
  "https://www.miaofoods.com/cate/WXK3SBRR7P.html",
  "https://www.miaofoods.com/cate/0W7DENFIXN.html",
  "https://www.miaofoods.com/cate/3G47JL72JO.html",
  "https://www.miaofoods.com/cate/F5BPE9QVQ3.html",
  "https://www.miaofoods.com/cate/QG5OZA15Y4.html",
  "https://www.miaofoods.com/cate/IRAT5Z42SD.html",
  "https://www.miaofoods.com/cate/WXOXSSCOTT.html",
  "https://www.miaofoods.com/cate/H9FC35SAGG.html",
  "https://www.miaofoods.com/cate/44ELNPAHH8.html",
  "https://www.miaofoods.com/cate/UCRVG0PAR4.html",
  "https://www.miaofoods.com/cate/YRW7UJVW9L.html",
  "https://www.miaofoods.com/cate/D0BXJ44193.html",
  "https://www.miaofoods.com/cate/W0DF1F7CYK.html",
  "https://www.miaofoods.com/cate/2MJDHYWZK8.html",
  "https://www.miaofoods.com/cate/LKCBB2LDMG.html",
  "https://www.miaofoods.com/cate/ADUDM0SF95.html"
];

function extractNuxtState(html) {
  const start = html.indexOf("window.__NUXT__=");
  if (start === -1) {
    throw new Error("window.__NUXT__ not found");
  }

  const end = html.indexOf("</script>", start);
  if (end === -1) {
    throw new Error("NUXT script closing tag not found");
  }

  const script = html.slice(start, end);
  const context = { window: {} };
  vm.runInNewContext(script, context);

  if (!context.window.__NUXT__) {
    throw new Error("Failed to evaluate NUXT state");
  }

  return context.window.__NUXT__;
}

function csvEscape(value) {
  return `"${String(value ?? "").replace(/"/g, "\"\"")}"`;
}

function htmlEscape(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

async function fetchCategory(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to fetch ${url}: ${response.status}`);
  }

  const html = await response.text();
  const nuxt = extractNuxtState(html);
  const page = nuxt.data && nuxt.data[0] ? nuxt.data[0] : {};
  const categoryName =
    (page.curCateInfo && page.curCateInfo.cateName) ||
    path.basename(url, ".html");
  const foods = Array.isArray(page.curCateFoodList) ? page.curCateFoodList : [];

  return foods.map((food) => ({
    category: categoryName,
    food_name: food.foodName || "",
    calories_kcal_per_100g: food.foodCaloriesVal ?? "",
    fat_g_per_100g: food.foodFatVal ?? "",
    carbs_g_per_100g: food.foodCarbohydrateVal ?? ""
  }));
}

async function main() {
  const rows = [];

  for (const url of urls) {
    const foods = await fetchCategory(url);
    rows.push(...foods);
  }

  const deduped = [];
  const seen = new Set();
  for (const row of rows) {
    const key = JSON.stringify(row);
    if (!seen.has(key)) {
      seen.add(key);
      deduped.push(row);
    }
  }

  deduped.sort((a, b) => {
    if (a.category !== b.category) {
      return a.category.localeCompare(b.category, "zh-Hans-CN");
    }
    return a.food_name.localeCompare(b.food_name, "zh-Hans-CN");
  });

  const outDir = process.cwd();
  const csvPath = path.join(outDir, "miaofoods_nutrition.csv");
  const jsonPath = path.join(outDir, "miaofoods_nutrition.json");
  const htmlPath = path.join(outDir, "miaofoods_nutrition.html");

  const csvHeader = [
    "category",
    "food_name",
    "calories_kcal_per_100g",
    "fat_g_per_100g",
    "carbs_g_per_100g"
  ].join(",");
  const csvBody = deduped.map((row) =>
    [
      row.category,
      row.food_name,
      row.calories_kcal_per_100g,
      row.fat_g_per_100g,
      row.carbs_g_per_100g
    ]
      .map(csvEscape)
      .join(",")
  );
  fs.writeFileSync(csvPath, "\uFEFF" + [csvHeader, ...csvBody].join("\n"), "utf8");

  fs.writeFileSync(jsonPath, JSON.stringify(deduped, null, 2), "utf8");

  const htmlRows = deduped
    .map(
      (row) =>
        `<tr><td>${htmlEscape(row.category)}</td><td>${htmlEscape(
          row.food_name
        )}</td><td>${htmlEscape(
          row.calories_kcal_per_100g
        )}</td><td>${htmlEscape(row.fat_g_per_100g)}</td><td>${htmlEscape(
          row.carbs_g_per_100g
        )}</td></tr>`
    )
    .join("\n");
  const html = `<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Miaofoods 食物营养表</title>
  <style>
    body { font-family: "Segoe UI", "Microsoft YaHei", sans-serif; margin: 24px; color: #222; background: #fafafa; }
    h1 { margin: 0 0 16px; font-size: 24px; }
    .meta { margin: 0 0 16px; color: #555; }
    table { width: 100%; border-collapse: collapse; background: #fff; }
    th, td { border: 1px solid #d8d8d8; padding: 8px 10px; text-align: left; font-size: 14px; }
    th { background: #f3f3f3; position: sticky; top: 0; }
    tr:nth-child(even) { background: #fcfcfc; }
  </style>
</head>
<body>
  <h1>Miaofoods 食物营养表</h1>
  <p class="meta">共 ${deduped.length} 条，单位统一为每 100 克。</p>
  <table>
    <thead>
      <tr>
        <th>分类</th>
        <th>食物名称</th>
        <th>热量(千卡/100克)</th>
        <th>脂肪(g/100克)</th>
        <th>碳水(g/100克)</th>
      </tr>
    </thead>
    <tbody>
      ${htmlRows}
    </tbody>
  </table>
</body>
</html>`;
  fs.writeFileSync(htmlPath, html, "utf8");

  console.log(
    JSON.stringify(
      {
        count: deduped.length,
        files: [csvPath, jsonPath, htmlPath]
      },
      null,
      2
    )
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
