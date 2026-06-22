import fs from 'node:fs'
import path from 'node:path'

const root = process.cwd()
const sourcePath = path.join(root, 'foods', 'miaofoods_nutrition.csv')
const outputPath = path.join(root, 'src', 'data', 'foodLibrary.js')

const categoryLabels = {
  '0DQM1ZK2G6': '主食谷薯',
  '0W7DENFIXN': '酸奶乳品',
  '2MJDHYWZK8': '水与气泡饮',
  '2VFC753X2J': '麦片谷物',
  '3G47JL72JO': '奶粉营养品',
  '3STTPBRR3I': '豆制品',
  '44ELNPAHH8': '调味料',
  ADUDM0SF95: '果汁饮料',
  AZ07CSC20I: '蛋类',
  D0BXJ44193: '咖啡可可',
  DBYCATD8RM: '水果',
  F5BPE9QVQ3: '奶酪黄油',
  GRH51YS6SJ: '蔬菜',
  H9FC35SAGG: '蜂蜜糖浆',
  IRAT5Z42SD: '奶油黄油',
  JSNC9WDKIF: '菌菇',
  LKCBB2LDMG: '乳饮奶茶',
  NP8Z3NMATH: '便当面点',
  QG5OZA15Y4: '食用油',
  TE2R3V4FC3: '肉类熟食',
  UCRVG0PAR4: '冰品甜点',
  W0DF1F7CYK: '饼干烘焙',
  WXK3SBRR7P: '牛奶',
  WXOXSSCOTT: '坚果种子',
  YRW7UJVW9L: '零食糖巧',
  YTJ3BXF4K7: '鱼禽海鲜'
}

function parseCsv(text) {
  const rows = []
  let row = []
  let cell = ''
  let quoted = false

  for (let index = 0; index < text.length; index += 1) {
    const char = text[index]
    const next = text[index + 1]

    if (char === '"') {
      if (quoted && next === '"') {
        cell += '"'
        index += 1
      } else {
        quoted = !quoted
      }
    } else if (char === ',' && !quoted) {
      row.push(cell)
      cell = ''
    } else if ((char === '\n' || char === '\r') && !quoted) {
      if (char === '\r' && next === '\n') index += 1
      row.push(cell)
      if (row.some((value) => value.length)) rows.push(row)
      row = []
      cell = ''
    } else {
      cell += char
    }
  }

  if (cell.length || row.length) {
    row.push(cell)
    rows.push(row)
  }

  return rows
}

function toNumber(value) {
  const parsed = Number(value)
  return Number.isFinite(parsed) ? Number(parsed.toFixed(2)) : 0
}

function makeId(name, index) {
  const slug = Array.from(name)
    .map((char) => char.codePointAt(0).toString(36))
    .join('-')
    .slice(0, 80)
  return `mf-${index + 1}-${slug}`
}

const csv = fs.readFileSync(sourcePath, 'utf8').replace(/^\uFEFF/, '')
const [, ...rows] = parseCsv(csv)

const foods = rows
  .map(([categoryCode, name, kcal, fat, carbs], index) => {
    const kcalPer100g = toNumber(kcal)
    const fatPer100g = toNumber(fat)
    const carbsPer100g = toNumber(carbs)
    const proteinPer100g = Math.max(
      0,
      toNumber((kcalPer100g - carbsPer100g * 4 - fatPer100g * 9) / 4)
    )

    return {
      id: makeId(name, index),
      name,
      alias: [],
      category: categoryLabels[categoryCode] || '食物库',
      categoryCode,
      source: 'miaofoods',
      kcalPer100g,
      proteinPer100g,
      carbsPer100g,
      fatPer100g
    }
  })
  .filter((food) => food.name && food.kcalPer100g > 0)

const compactRows = foods.map((food) => [
  food.name,
  food.category,
  food.categoryCode,
  food.kcalPer100g,
  food.proteinPer100g,
  food.carbsPer100g,
  food.fatPer100g
])

fs.mkdirSync(path.dirname(outputPath), { recursive: true })
fs.writeFileSync(
  outputPath,
  `// Auto-generated from foods/miaofoods_nutrition.csv. Run \`npm run build:foods\` after updating the source.\nconst foodRows = ${JSON.stringify(compactRows)}\n\nexport const foodLibrary = foodRows.map(([name, category, categoryCode, kcalPer100g, proteinPer100g, carbsPer100g, fatPer100g], index) => ({\n  id: \`mf-\${index + 1}\`,\n  name,\n  alias: [],\n  category,\n  categoryCode,\n  source: 'miaofoods',\n  kcalPer100g,\n  proteinPer100g,\n  carbsPer100g,\n  fatPer100g\n}))\n\nexport const foodLibraryMeta = ${JSON.stringify({ count: foods.length, source: 'miaofoods' })}\n`,
  'utf8'
)

console.log(JSON.stringify({ sourcePath, outputPath, count: foods.length }, null, 2))
