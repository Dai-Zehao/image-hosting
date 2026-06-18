# R6 Care

R6 Care 是一个健康管理 Web 软件起步工程，当前包含：

- Vue 3 主界面组件：[src/components/zhujiemian.vue](C:/Users/30447/Documents/r6%20care%202/src/components/zhujiemian.vue)
- Supabase/PostgreSQL 数据库结构：[supabase/schema.sql](C:/Users/30447/Documents/r6%20care%202/supabase/schema.sql)
- 产品与公式说明：[docs/R6-Care-product-notes.md](C:/Users/30447/Documents/r6%20care%202/docs/R6-Care-product-notes.md)

## 本地运行

```bash
npm install
npm run dev
```

## Supabase 初始化

1. 在 Supabase 创建新项目。
2. 打开 SQL Editor。
3. 执行 `supabase/schema.sql`。
4. 复制 `.env.example` 为 `.env.local`，填入项目 URL 和 anon key。

## 计算说明

首页使用 Mifflin-St Jeor 公式估算 BMR，并用活动系数得到 TDEE。仅根据身高和性别无法可靠计算每日热量，R6 Care 会要求用户补齐年龄、体重和活动水平。
