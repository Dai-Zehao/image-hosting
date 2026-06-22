import rawSports from '../../sports/sports_calories_30min.json'

const sportsLibrary = (Array.isArray(rawSports) ? rawSports : []).map((item) => ({
  id: item.id,
  category_zh: item.category_zh,
  name_zh: item.name_zh,
  intensity_zh: item.intensity_zh,
  met: Number(item.met || 0),
  kcal_30min_70kg: Number(item.kcal_30min_70kg || 0),
  source_code: item.source_code,
  source_activity_en: item.source_activity_en
}))

export default sportsLibrary
