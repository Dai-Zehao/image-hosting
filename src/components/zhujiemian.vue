<template>
  <main class="care-app">
    <div class="ambient" aria-hidden="true">
      <span class="sheet sheet-a"></span>
      <span class="sheet sheet-b"></span>
      <span class="sheet sheet-c"></span>
    </div>

    <R6Glass class-name="side-rail" padding="18px" :corner-radius="28">
      <div class="brand">
        <span class="logo-glass">
          <img src="/assets/r6care-app-icon.png" alt="R6 Studio" />
        </span>
        <div>
          <strong>R6 Care</strong><small>健康管理</small>
        </div>
      </div>

      <nav aria-label="主导航">
        <button
          v-for="item in navItems"
          :key="item.key"
          :class="{ active: activeSection === item.key }"
          type="button"
          @click="activeSection = item.key"
        >
          <component :is="item.icon" :size="19" />
          <span>{{ item.label }}</span>
        </button>
      </nav>

      <button
        v-if="!isStandalonePwa"
        class="install-nav"
        type="button"
        @click="handleInstallApp"
      >
        <Download :size="18" />
        <span>{{ installButtonLabel }}</span>
        <ChevronRight :size="16" />
      </button>

      <div class="rail-status">
        <small>{{ sessionUser ? '今日剩余' : '账户状态' }}</small>
        <strong>{{ sessionUser ? `${remainingCalories} kcal` : '未登录' }}</strong>
        <span>{{ sessionUser ? '可用热量空间' : '登录后保存个人数据' }}</span>
      </div>
    </R6Glass>

    <section class="main-board">
      <header class="topline">
        <div>
          <p>{{ pageHeader.kicker }} / {{ todayLabel }}</p>
          <Transition name="title-fade" mode="out-in">
            <h1 :key="pageHeader.title">{{ pageHeader.title }}</h1>
          </Transition>
        </div>
        <div class="top-actions">
          <button
            v-if="!isStandalonePwa"
            class="install-mini"
            type="button"
            :aria-label="installButtonLabel"
            @click="handleInstallApp"
          >
            <Download :size="16" />
          </button>
          <button class="author-bubble" type="button" aria-label="打开作者的话" @click="showAuthorModal = true">
            <MessageCircle :size="16" />
            <span>通知</span>
          </button>
          <button class="glass-button account" type="button" @click="handleAccountEntry">
            <User :size="18" />
            {{ sessionUser ? sessionUser.name : '登录 / 注册' }}
          </button>
        </div>
      </header>

      <section v-if="activeSection === 'overview'" class="dashboard-grid">
        <R6Glass class-name="hero-meter" padding="28px" :corner-radius="32">
          <div class="meter-copy">
            <p class="eyebrow">剩余热量空间</p>
            <div class="mega-number">
              <strong>{{ remainingCalories }}</strong>
              <span>kcal</span>
            </div>
            <p class="hint">基于 Mifflin-St Jeor 国际公式估算基础代谢与平均消耗，再结合今日摄入实时计算。</p>
          </div>

          <div
            class="ring-wrap"
            :class="{ 'is-over': isOverCalories }"
            :style="{ '--offset': calorieOffset }"
          >
            <div class="svg-ring">
              <svg viewBox="0 0 160 160" role="img" aria-label="今日热量使用进度">
                <defs>
                  <linearGradient id="calorie-ring-gradient" x1="34" y1="22" x2="126" y2="138" gradientUnits="userSpaceOnUse">
                    <stop offset="0%" stop-color="#1bc8ff" />
                    <stop offset="48%" stop-color="#49ead6" />
                    <stop offset="100%" stop-color="#c7ff66" />
                  </linearGradient>
                  <filter id="calorie-ring-glow" x="-35%" y="-35%" width="170%" height="170%">
                    <feGaussianBlur stdDeviation="4.5" result="blur" />
                    <feColorMatrix in="blur" type="matrix" values="0 0 0 0 0.1 0 0 0 0 0.82 0 0 0 0 0.75 0 0 0 .55 0" />
                    <feMerge>
                      <feMergeNode />
                      <feMergeNode in="SourceGraphic" />
                    </feMerge>
                  </filter>
                </defs>
                <circle class="svg-ring-track" cx="80" cy="80" r="62" />
                <circle
                  v-if="calorieRingProgress >= 100"
                  class="svg-ring-complete"
                  cx="80"
                  cy="80"
                  r="62"
                />
                <circle
                  class="svg-ring-progress"
                  :class="{ empty: calorieRingProgress === 0, full: calorieRingProgress >= 100 }"
                  cx="80"
                  cy="80"
                  r="62"
                  pathLength="100"
                />
              </svg>
              <div class="ring-core">
                <strong>{{ calorieProgress }}%</strong>
                <small>已使用</small>
              </div>
            </div>
            <p v-if="isOverCalories" class="calorie-alert">超出啦~快去运动找回缺口</p>
          </div>

          <div class="metric-row">
            <div><span>平均消耗</span><strong>{{ roundedTdee }}</strong></div>
            <div><span>今日摄入</span><strong>{{ todayCalories }}</strong></div>
            <div><span>目标热量</span><strong>{{ targetCalories }}</strong></div>
          </div>

          <div class="hero-macros">
            <div class="hero-macros-head">
              <span>宏量营养</span>
              <strong>{{ macrosTotal }}g</strong>
            </div>
            <div class="hero-macro-stack">
              <div v-for="macro in macros" :key="macro.name">
                <span>{{ macro.name }}</span>
                <strong>{{ macro.value }}g</strong>
                <i :style="{ width: `${macro.percent}%` }"></i>
              </div>
            </div>
          </div>

          <div class="hero-status-line">
            <span>今日状态</span>
            <p>{{ heroStatusMessage }}</p>
          </div>
        </R6Glass>

        <R6Glass class-name="quick-add" :corner-radius="30">
          <div class="card-head">
            <div>
              <p class="eyebrow">记录摄入</p>
              <h2>{{ foodInputMode === 'search' ? '搜索食物' : '我的自定义摄入' }}</h2>
            </div>
            <Utensils :size="22" />
          </div>
          <form class="add-form" @submit.prevent="addFood">
            <div class="mode-switch">
              <button type="button" :class="{ active: foodInputMode === 'search' }" @click="foodInputMode = 'search'">搜索食物</button>
              <button type="button" :class="{ active: foodInputMode === 'custom' }" @click="foodInputMode = 'custom'">我的自定义摄入</button>
            </div>

            <template v-if="foodInputMode === 'search'">
              <div class="food-search">
                <Search :size="18" />
                <input v-model.trim="foodSearchQuery" aria-label="搜索食物" placeholder="搜索：红薯、米饭、鸡胸肉..." />
              </div>
              <div class="result-list" aria-label="食物搜索结果">
                <button
                  v-for="food in filteredFoodLibrary"
                  :key="food.id"
                  type="button"
                  :class="{ selected: selectedFoodId === food.id }"
                  @click="selectFood(food)"
                >
                  <span>
                    <strong>{{ food.name }}</strong>
                    <small>{{ food.category }} · {{ food.source }}</small>
                  </span>
                  <em>{{ food.kcalPer100g }} kcal/100g</em>
                </button>
              </div>

              <div class="selected-food">
                <div>
                  <span>已选择</span>
                  <strong>{{ selectedFood.name }}</strong>
                  <small>每100g：蛋白 {{ selectedFood.proteinPer100g }}g / 碳水 {{ selectedFood.carbsPer100g }}g / 脂肪 {{ selectedFood.fatPer100g }}g</small>
                </div>
                <label class="grams-field">
                  <div class="grams-topline">
                    <div class="grams-meta grams-meta-kcal">
                      <span>预计</span>
                      <small class="inline-kcal"><strong>{{ calculatedFood.kcal }}</strong> kcal</small>
                    </div>
                    <div class="grams-meta grams-meta-input">
                      <span>摄入克数</span>
                      <div class="grams-control">
                        <input v-model.number="foodDraft.grams" aria-label="摄入克数" type="number" min="1" max="3000" />
                        <em>g</em>
                      </div>
                    </div>
                  </div>
                  <input
                    v-model.number="foodDraft.grams"
                    class="grams-slider"
                    aria-label="滑动调整摄入克数"
                    type="range"
                    min="1"
                    max="1000"
                    step="1"
                    :style="{ '--fill': `${Math.min(100, Math.max(0, (Number(foodDraft.grams || 0) / 1000) * 100))}%` }"
                  />
                </label>
              </div>

              <button type="submit">
                <Plus :size="18" />
                加入今日摄入
              </button>
            </template>

            <template v-else>
              <div class="custom-entry-form">
                <label>
                  <span>名称</span>
                  <input v-model.trim="customFoodDraft.name" aria-label="自定义摄入名称" placeholder="例如：奶茶半糖、家常便当" />
                </label>
                <label>
                  <span>大卡</span>
                  <input v-model.number="customFoodDraft.kcal" aria-label="自定义摄入大卡" type="number" min="1" max="6000" placeholder="输入总热量" />
                </label>
                <div class="custom-actions">
                  <button type="button" class="secondary-action" @click="saveCustomFood(false)">仅保存</button>
                  <button type="button" @click="saveCustomFood(true)">
                    <Plus :size="18" />
                    保存并摄入
                  </button>
                </div>
              </div>
              <div class="custom-list" aria-label="我的自定义摄入列表">
                <div
                  v-for="item in customFoods"
                  :key="item.id"
                  class="custom-item"
                >
                  <span>
                    <strong>{{ item.name }}</strong>
                    <small>我的自定义摄入</small>
                  </span>
                  <em>{{ item.kcal }} kcal</em>
                  <button class="add-preset" type="button" @click="addCustomFoodToToday(item)">加入</button>
                  <button class="delete-preset" type="button" aria-label="删除自定义摄入" @click="removeCustomFood(item)">
                    <Trash2 :size="15" />
                    <span>删除</span>
                  </button>
                </div>
                <p v-if="!customFoods.length" class="empty-state">还没有自定义摄入，先保存一个常吃项目。</p>
              </div>
              <p v-if="customFoodMessage" class="inline-feedback">{{ customFoodMessage }}</p>
            </template>
          </form>
        </R6Glass>

        <FoodLog :foods="foods" title="今日摄入明细" :headline="`${todayCalories} kcal`" eyebrow="今日明细" @remove="removeFood" />

      </section>

      <section v-else-if="activeSection === 'intake'" class="feature-grid">
        <R6Glass class-name="planner-card exercise-builder" :corner-radius="28">
          <div class="card-head">
            <div>
              <p class="eyebrow">运动记录</p>
              <h2>{{ exerciseInputMode === 'search' ? '搜索运动项目' : '我的自定义运动' }}</h2>
            </div>
            <Activity :size="22" />
          </div>
          <div class="exercise-form">
            <div class="mode-switch">
              <button type="button" :class="{ active: exerciseInputMode === 'search' }" @click="exerciseInputMode = 'search'">搜索运动</button>
              <button type="button" :class="{ active: exerciseInputMode === 'custom' }" @click="exerciseInputMode = 'custom'">我的自定义运动</button>
            </div>

            <template v-if="exerciseInputMode === 'search'">
              <div class="food-search">
                <Search :size="18" />
                <input
                  v-model.trim="exerciseSearchQuery"
                  aria-label="搜索运动项目"
                  placeholder="搜索：快走、力量训练、羽毛球、游泳..."
                />
              </div>

              <div class="category-pills">
                <button
                  v-for="category in exerciseCategoryList"
                  :key="category"
                  type="button"
                  :class="{ active: exerciseCategory === category }"
                  @click="exerciseCategory = category"
                >
                  {{ category }}
                </button>
              </div>

              <div class="result-list exercise-results" aria-label="运动搜索结果">
                <button
                  v-for="sport in filteredSportsLibrary"
                  :key="sport.id"
                  type="button"
                  :class="{ selected: selectedExerciseId === sport.id }"
                  @click="selectExercise(sport)"
                >
                  <span>
                    <strong>{{ sport.name_zh }}</strong>
                    <small>{{ sport.category_zh }} · {{ sport.intensity_zh }} · MET {{ sport.met }}</small>
                  </span>
                  <em>{{ sport.kcal_30min_70kg }} kcal / 30分钟</em>
                </button>
              </div>

              <div class="exercise-preview-grid">
                <div>
                  <span>预计消耗</span>
                  <strong>{{ calculatedExercise.kcal }}</strong>
                  <small>kcal</small>
                </div>
                <div>
                  <span>当前 MET</span>
                  <strong>{{ calculatedExercise.met }}</strong>
                  <small>{{ selectedExercise.intensity_zh || '强度' }}</small>
                </div>
                <div class="duration-tile">
                  <span>运动时长</span>
                  <label>
                    <input v-model.number="exerciseDraft.duration" aria-label="运动时长" type="number" min="5" max="360" step="5" />
                    <small>分钟</small>
                  </label>
                </div>
              </div>

              <button type="button" @click="addExercise">
                <Plus :size="18" />
                加入今日运动
              </button>
            </template>

            <template v-else>
              <div class="custom-entry-form">
                <label>
                  <span>名称</span>
                  <input v-model.trim="customExerciseDraft.name" aria-label="自定义运动名称" placeholder="例如：楼梯训练、通勤骑行" />
                </label>
                <label>
                  <span>消耗大卡</span>
                  <input v-model.number="customExerciseDraft.kcal" aria-label="自定义运动消耗大卡" type="number" min="1" max="4000" placeholder="输入消耗热量" />
                </label>
                <div class="custom-actions">
                  <button type="button" class="secondary-action" @click="saveCustomExercise(false)">仅保存</button>
                  <button type="button" @click="saveCustomExercise(true)">
                    <Plus :size="18" />
                    保存并记录
                  </button>
                </div>
              </div>
              <div class="custom-list" aria-label="我的自定义运动列表">
                <div
                  v-for="item in customExercises"
                  :key="item.id"
                  class="custom-item"
                >
                  <span>
                    <strong>{{ item.name_zh }}</strong>
                    <small>我的自定义运动</small>
                  </span>
                  <em>{{ item.kcal }} kcal</em>
                  <button class="add-preset" type="button" @click="addCustomExerciseToToday(item)">加入</button>
                  <button class="delete-preset" type="button" aria-label="删除自定义运动" @click="removeCustomExercise(item)">
                    <Trash2 :size="15" />
                    <span>删除</span>
                  </button>
                </div>
                <p v-if="!customExercises.length" class="empty-state">还没有自定义运动，先保存一个常用项目。</p>
              </div>
              <p v-if="customExerciseMessage" class="inline-feedback">{{ customExerciseMessage }}</p>
            </template>
          </div>
        </R6Glass>

        <R6Glass class-name="planner-card exercise-summary-card" :corner-radius="28">
          <div class="card-head">
            <div>
              <p class="eyebrow">运动反馈</p>
              <h2>{{ todayExerciseCalories }} kcal</h2>
            </div>
            <span class="total-pill">{{ exerciseCount }} 项</span>
          </div>
          <div class="target-summary">
            <div><span>今日运动</span><strong>{{ todayExerciseCalories }}</strong></div>
            <div><span>新增空间</span><strong>{{ effectiveCaloriesBudget - targetCalories }}</strong></div>
            <div><span>最高消耗</span><strong>{{ exercisePeakBurn }}</strong></div>
          </div>
          <div class="exercise-highlight">
            <p>{{ exerciseLeadText }}</p>
            <div class="exercise-quick-grid">
              <button v-for="item in exerciseQuickPicks" :key="item.id" type="button" @click="selectExercise(item)">
                <strong>{{ item.name_zh }}</strong>
                <span>{{ item.category_zh }} · {{ item.kcal_30min_70kg }} kcal / 30分钟</span>
              </button>
            </div>
          </div>
        </R6Glass>

        <ExerciseLog :items="exercises" :headline="`${todayExerciseCalories} kcal`" @remove="removeExercise" />
      </section>

      <section v-else-if="activeSection === 'weight'" class="feature-grid">
        <R6Glass class-name="planner-card wide-feature weight-studio" :corner-radius="30">
          <div class="card-head weight-head">
            <div>
              <p class="eyebrow">体重趋势</p>
              <h2>{{ currentWeight }} kg</h2>
            </div>
            <span class="total-pill">{{ weightDeltaText }}</span>
          </div>
          <div class="weight-status-grid">
            <div>
              <span>当前状态</span>
              <strong>{{ weightTrendStatus }}</strong>
            </div>
            <div>
              <span>7天均值</span>
              <strong>{{ averageWeight }} kg</strong>
            </div>
            <div>
              <span>距离起点</span>
              <strong>{{ weightDeltaText }}</strong>
            </div>
          </div>
          <WeightBars :points="weightPoints" :current="currentWeight" :delta="weightDelta" large />
          <form class="weight-form inline" @submit.prevent="addWeight">
            <input v-model.number="weightDraft" type="number" min="30" max="250" step="0.1" aria-label="今日体重" />
            <button type="submit">记录今日体重</button>
          </form>
        </R6Glass>
      </section>

      <section v-else-if="activeSection === 'target'" class="feature-grid">
        <R6Glass class-name="planner-card" :corner-radius="28">
          <div class="card-head">
            <div>
              <p class="eyebrow">目标设置</p>
              <h2>每日热量目标</h2>
            </div>
            <Target :size="22" />
          </div>
          <form class="target-form" @submit.prevent="saveDailyTarget">
            <label>
              <span>目标模式</span>
              <select v-model="goal.mode">
                <option value="auto">按平均消耗自动</option>
                <option value="lose">减脂 -15%</option>
                <option value="maintain">维持</option>
                <option value="gain">增肌 +10%</option>
                <option value="custom">自定义</option>
              </select>
            </label>
            <label>
              <span>自定义目标 kcal</span>
              <input v-model.number="goal.customCalories" type="number" min="800" max="6000" />
            </label>
            <button type="submit">保存目标</button>
          </form>
        </R6Glass>
        <R6Glass class-name="planner-card" :corner-radius="28">
          <div class="card-head">
            <div>
              <p class="eyebrow">目标概览</p>
              <h2>{{ targetCalories }} kcal</h2>
            </div>
            <span class="total-pill">{{ goalLabel }}</span>
          </div>
          <p class="target-summary-copy">这里展示当前生效的每日热量目标，以及它和今天摄入、平均消耗之间的关系。</p>
          <div class="target-summary">
            <div><span>平均消耗</span><strong>{{ roundedTdee }}</strong></div>
            <div><span>今日摄入</span><strong>{{ todayCalories }}</strong></div>
            <div><span>剩余空间</span><strong>{{ remainingCalories }}</strong></div>
          </div>
        </R6Glass>
      </section>

      <section v-else-if="activeSection === 'calendar'" class="feature-grid">
        <R6Glass class-name="planner-card wide-feature calendar-studio" :corner-radius="28">
          <div class="card-head">
            <div>
              <p class="eyebrow">整月视图</p>
              <h2>{{ calendarMonthLabel }}</h2>
            </div>
            <div class="calendar-nav">
              <button type="button" class="icon-plain" aria-label="上个月" @click="shiftCalendarMonth(-1)">
                <ChevronLeft :size="18" />
              </button>
              <button type="button" class="icon-plain" aria-label="下个月" @click="shiftCalendarMonth(1)">
                <ChevronRight :size="18" />
              </button>
            </div>
          </div>
          <div class="calendar-summary-strip">
            <div>
              <span>当前目标</span>
              <strong>{{ targetCalories }} kcal</strong>
            </div>
            <div>
              <span>今日剩余</span>
              <strong>{{ remainingCalories }}</strong>
            </div>
            <div>
              <span>本月记录</span>
              <strong>{{ calendarRecordedCount }}</strong>
            </div>
          </div>
          <div class="calendar-grid">
            <span v-for="weekday in calendarWeekdays" :key="weekday" class="calendar-weekday">{{ weekday }}</span>
            <button
              v-for="day in calendarDays"
              :key="day.dateKey"
              type="button"
              class="calendar-day"
              :class="{ 'is-muted': !day.isCurrentMonth, 'is-today': day.isToday, 'is-over': day.remaining < 0 }"
              @click="calendarMonth = new Date(day.dateKey)"
            >
              <small>{{ day.dayNumber }}</small>
              <strong>{{ day.remaining }}</strong>
              <span>{{ day.status }}</span>
            </button>
          </div>
        </R6Glass>
      </section>

      <section v-else class="feature-grid">
        <R6Glass class-name="planner-card" :corner-radius="28">
          <div class="card-head">
            <div>
              <p class="eyebrow">账户中心</p>
              <h2>{{ sessionUser ? sessionUser.name : '未登录' }}</h2>
            </div>
            <User :size="22" />
          </div>
          <div class="account-summary">
            <div><span>邮箱</span><strong>{{ sessionUser?.authEmail && !sessionUser.authEmail.endsWith('@r6care.local') ? sessionUser.authEmail : '未绑定' }}</strong></div>
            <div><span>资料状态</span><strong>{{ sessionUser?.profileComplete ? '已完成' : '待完善' }}</strong></div>
            <div><span>账户模式</span><strong>{{ accountModeLabel }}</strong></div>
          </div>
          <div class="account-actions">
            <button v-if="sessionUser" class="secondary-action" type="button" @click="openProfileEditor">
              <Settings :size="17" />
              修改身体参数
            </button>
            <button v-if="sessionUser" class="danger-action" type="button" @click="logout">
              <LogOut :size="17" />
              退出登录
            </button>
            <button v-else class="secondary-action" type="button" @click="openAuth('login')">
              <LogIn :size="17" />
              登录 / 注册
            </button>
          </div>
        </R6Glass>

        <R6Glass class-name="planner-card" :corner-radius="28">
          <div class="card-head">
            <div>
              <p class="eyebrow">个人资料</p>
              <h2>身体参数</h2>
            </div>
            <Activity :size="22" />
          </div>
          <div class="body-readout">
            <div v-for="item in bodyReadout" :key="item.label" class="body-readout-item">
              <span>{{ item.label }}</span>
              <strong>{{ item.value }}</strong>
              <small>{{ item.hint }}</small>
            </div>
          </div>
          <p class="profile-readonly-note">身体参数仅用于计算每日平均消耗。需要调整时，请使用“修改身体参数”。</p>
        </R6Glass>
      </section>
    </section>

    <Transition name="modal-rise">
    <section v-if="showAuthModal" class="modal-layer" role="dialog" aria-modal="true">
      <R6Glass class-name="auth-card login-card" :corner-radius="38" padding="0">
        <form class="modal-form" @submit.prevent="submitAuth">
          <button class="auth-close icon-plain" type="button" aria-label="关闭" @click="closeAuth">
            <X :size="20" />
          </button>
          <div class="auth-showcase">
            <span class="auth-mark logo-glass">
              <img src="/assets/r6care-app-icon.png" alt="R6 Studio" />
            </span>
            <div>
              <p class="eyebrow">R6 Care Account</p>
              <h2 v-if="authMode === 'login'">欢迎回来</h2>
              <h2 v-else>创建你的<br />健康档案</h2>
              <p>{{ authMode === 'login' ? '同步每日摄入、热量空间和体重趋势。' : '开启你的健康之旅' }}</p>
            </div>
            <div class="auth-flow-tags">
              <span>{{ authMode === 'login' ? '同步数据' : '身体参数' }}</span>
              <span>{{ authMode === 'login' ? '目标策略' : '热量公式' }}</span>
              <span>{{ authMode === 'login' ? '体重趋势' : '开始记录' }}</span>
            </div>
          </div>

          <div class="auth-fields">
            <div class="auth-title">
              <h2>{{ authMode === 'login' ? '登录 R6 Care' : '注册账户' }}</h2>
              <p v-if="!hasSupabaseConfig" class="auth-config-tip">当前还没有配置 Supabase，部署后填写环境变量即可开启真实账户。</p>
            </div>
            <label v-if="authMode === 'register'">
              <span>用户名</span>
              <input
                v-model="authForm.name"
                required
                type="text"
                inputmode="latin"
                autocomplete="username"
                pattern="[A-Za-z0-9]+"
                maxlength="24"
                placeholder="仅限英文或数字"
                @input="authForm.name = sanitizeAccountInput(authForm.name)"
              />
            </label>
            <label v-if="authMode === 'login'">
              <span>用户名</span>
              <input
                v-model="authForm.email"
                required
                type="text"
                inputmode="latin"
                autocomplete="username"
                pattern="[A-Za-z0-9]+"
                maxlength="24"
                placeholder="请输入用户名"
                @input="authForm.email = sanitizeAccountInput(authForm.email)"
              />
            </label>
            <label>
              <span>密码</span>
              <input
                v-model="authForm.password"
                required
                type="password"
                inputmode="latin"
                autocomplete="current-password"
                pattern="[A-Za-z0-9]+"
                minlength="6"
                maxlength="32"
                placeholder="请输入密码"
                @input="authForm.password = sanitizeAccountInput(authForm.password)"
              />
            </label>
            <p v-if="authMode === 'register'" class="auth-config-tip">用户名和密码仅支持英文或数字，邮箱后续可以再补充。</p>
            <p v-if="authMessage" class="form-message">{{ authMessage }}</p>
            <div class="auth-actions">
              <button class="primary-action" type="submit" :disabled="authLoading">
                <KeyRound :size="18" />
                {{ authLoading ? '处理中...' : authMode === 'login' ? '登录' : '创建账户' }}
              </button>
              <button class="text-action" type="button" @click="toggleAuthMode">
                {{ authMode === 'login' ? '没有账户？立即注册' : '已有账户？返回登录' }}
              </button>
            </div>
          </div>
        </form>
      </R6Glass>
    </section>
    </Transition>

    <Transition name="modal-rise">
    <section v-if="showProfileModal" class="modal-layer" role="dialog" aria-modal="true">
      <R6Glass class-name="auth-card profile-modal" :corner-radius="34">
        <form class="profile-form" @submit.prevent="completeProfile">
          <div class="card-head">
            <div>
              <p class="eyebrow">{{ needsProfileSetup ? '首次登录' : '个人资料' }}</p>
              <h2>{{ needsProfileSetup ? '完善身体参数' : '修改身体参数' }}</h2>
            </div>
            <button v-if="!needsProfileSetup" class="icon-plain" type="button" aria-label="关闭" @click="showProfileModal = false">
              <X :size="20" />
            </button>
          </div>
          <p class="profile-intro">这些数据会用于计算每日平均消耗和热量空间，之后可以在个人资料页随时修改。</p>
          <ProfileFields v-model:profile="profile" :activity-options="activityOptions" @profile-change="markProfileTouched" />
          <p v-if="profileMessage" class="form-message">{{ profileMessage }}</p>
          <button class="primary-action" type="submit" :disabled="profileLoading">
            {{ profileLoading ? '保存中...' : '保存并进入系统' }}
          </button>
        </form>
      </R6Glass>
    </section>
    </Transition>

    <Transition name="author-modal">
      <section v-if="showAuthorModal" class="author-layer" role="dialog" aria-modal="true" aria-labelledby="author-note-title" @click.self="showAuthorModal = false">
        <div class="author-note">
          <button class="icon-plain author-close" type="button" aria-label="关闭作者的话" @click="showAuthorModal = false">
            <X :size="18" />
          </button>
          <div class="author-note-head">
            <span class="author-avatar">
              <img :src="authorAvatar" alt="作者头像" />
            </span>
            <div>
              <p>R6 Care Beta</p>
              <h2 id="author-note-title">作者想说</h2>
            </div>
          </div>
          <div class="author-note-body">
            <p>欢迎来到 R6 Care。现在它还是一个测试版本，很多细节还在继续打磨，也可能会遇到各种各样的 bug。</p>
            <p>如果你在使用过程中发现问题、体验不顺，或者有想加入的功能，欢迎随时反馈。你的每一次使用都会帮助它变得更完整。</p>
          </div>
          <div class="author-note-foot">
            <span>感谢体验</span>
            <strong>R6 Studio</strong>
          </div>
        </div>
      </section>
    </Transition>

    <Transition name="author-modal">
      <section v-if="showInstallGuide" class="author-layer" role="dialog" aria-modal="true" aria-labelledby="install-guide-title" @click.self="showInstallGuide = false">
        <div class="author-note install-note">
          <button class="icon-plain author-close" type="button" aria-label="关闭安装说明" @click="showInstallGuide = false">
            <X :size="18" />
          </button>
          <div class="author-note-head">
            <span class="author-avatar">
              <Download :size="26" />
            </span>
            <div>
              <p>R6 Care 安装</p>
              <h2 id="install-guide-title">添加到桌面</h2>
            </div>
          </div>
          <div class="author-note-body">
            <p v-if="isIOS">请在 Safari 里点“分享”，然后选择“添加到主屏幕”。这样它就会像 App 一样出现在桌面。</p>
            <p v-else>如果浏览器支持安装，会直接弹出安装窗口；如果没有弹窗，可以在浏览器菜单里选择“安装应用”或“添加到桌面”。</p>
          </div>
          <div class="author-note-foot">
            <span>{{ isIOS ? 'iPhone / iPad' : '安卓 / 电脑' }}</span>
            <strong>{{ isIOS ? '分享后添加' : '安装为应用' }}</strong>
          </div>
        </div>
      </section>
    </Transition>
  </main>
</template>

<script setup>
import { computed, defineComponent, h, onMounted, onBeforeUnmount, reactive, ref, watch } from 'vue'
import { createClient } from '@supabase/supabase-js'
import { GlassContainer } from '@wxperia/liquid-glass-vue'
import {
  Activity,
  BarChart3,
  CalendarDays,
  ChevronLeft,
  ChevronRight,
  KeyRound,
  Download,
  LogIn,
  LogOut,
  MessageCircle,
  Plus,
  RefreshCw,
  Scale,
  Search,
  Settings,
  Target,
  Trash2,
  User,
  Utensils,
  X
} from '@lucide/vue'
import authorAvatar from '../../by.jpg'
import sportsLibrary from '../data/sportsLibrary.js'

const STORAGE_KEY = 'r6-care-ui-state'
const SESSION_TOKEN_KEY = 'r6-care-session-token'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY
const hasSupabaseConfig = Boolean(
  supabaseUrl &&
  supabaseAnonKey &&
  !supabaseUrl.includes('your-project') &&
  !supabaseAnonKey.includes('your-anon-key')
)
const supabase = hasSupabaseConfig ? createClient(supabaseUrl, supabaseAnonKey) : null

const ProfileFields = defineComponent({
  props: {
    profile: { type: Object, required: true },
    activityOptions: { type: Array, required: true }
  },
  emits: ['profile-change'],
  setup(props, { emit }) {
    const update = (key, value) => {
      props.profile[key] = value
      emit('profile-change', { key, value })
    }
    const percent = (value, min, max) => `${Math.max(0, Math.min(100, ((Number(value) - min) / (max - min)) * 100))}%`
    const numberControl = ({ key, label, unit, min, max, step = 1, hint }) => h('label', { class: 'range-field' }, [
      h('div', { class: 'range-head' }, [
        h('span', label),
        h('strong', [
          h('input', {
            type: 'number',
            min,
            max,
            step,
            value: props.profile[key],
            onInput: (event) => update(key, Number(event.target.value))
          }),
          h('em', unit)
        ])
      ]),
      h('input', {
        class: 'profile-range',
        style: { '--fill': percent(props.profile[key], min, max) },
        type: 'range',
        min,
        max,
        step,
        value: props.profile[key],
        onInput: (event) => update(key, Number(event.target.value)),
        'aria-label': label
      }),
      h('div', { class: 'range-scale' }, [
        h('span', `${min}${unit}`),
        h('small', hint),
        h('span', `${max}${unit}`)
      ])
    ])

    return () => h('div', { class: 'profile-control-panel' }, [
      h('div', { class: 'profile-toggle-block' }, [
        h('span', '性别'),
        h('div', { class: 'segmented-control' }, [
          h('button', {
            type: 'button',
            class: props.profile.sex === 'female' ? 'active' : '',
            onClick: () => update('sex', 'female')
          }, '女'),
          h('button', {
            type: 'button',
            class: props.profile.sex === 'male' ? 'active' : '',
            onClick: () => update('sex', 'male')
          }, '男')
        ])
      ]),
      numberControl({ key: 'age', label: '年龄', unit: '岁', min: 12, max: 100, step: 1, hint: '影响基础代谢估算' }),
      numberControl({ key: 'heightCm', label: '身高', unit: 'cm', min: 120, max: 230, step: 0.1, hint: '拖动即可微调' }),
      numberControl({ key: 'weightKg', label: '体重', unit: 'kg', min: 30, max: 250, step: 0.1, hint: '会同步到账户体重记录' }),
      h('div', { class: 'activity-picker' }, [
        h('div', { class: 'activity-title' }, [
          h('span', '活动强度'),
          h('small', '用于计算每日平均消耗')
        ]),
        h('div', { class: 'activity-options' }, props.activityOptions.map((item) => h('button', {
          type: 'button',
          class: props.profile.activity === item.value ? 'active' : '',
          onClick: () => update('activity', item.value)
        }, [
          h('strong', item.label),
          h('span', `${item.factor}x`)
        ])))
      ])
    ])
  }
})

const R6Glass = defineComponent({
  props: {
    className: { type: String, default: '' },
    cornerRadius: { type: Number, default: 26 },
    padding: { type: String, default: '20px' },
    overLight: { type: Boolean, default: false }
  },
  setup(props, { slots }) {
    return () => h('div', { class: ['r6-shell', props.className] }, [
      h(GlassContainer, {
        className: 'r6-liquid',
        cornerRadius: props.cornerRadius,
        padding: props.padding,
        overLight: props.overLight,
        displacementScale: 64,
        blurAmount: 0.08,
        saturation: 135,
        aberrationIntensity: 1.6,
        elasticity: 0.2,
        mode: 'standard'
      }, slots)
    ])
  }
})

const WeightBars = defineComponent({
  props: {
    points: { type: Array, required: true },
    current: { type: [String, Number], default: '' },
    delta: { type: [String, Number], default: 0 },
    large: { type: Boolean, default: false }
  },
  setup(props) {
    return () => {
      const points = props.points.length ? props.points : []
      const coords = points.map((point, index) => ({
        ...point,
        x: 24 + (index / Math.max(1, points.length - 1)) * 312,
        y: 36 + (1 - Number(point.ratio || 0)) * 134
      }))
      const linePath = coords.map((point, index) => `${index ? 'L' : 'M'} ${point.x.toFixed(1)} ${point.y.toFixed(1)}`).join(' ')
      const areaPath = coords.length
        ? `${linePath} L ${coords.at(-1).x.toFixed(1)} 186 L ${coords[0].x.toFixed(1)} 186 Z`
        : ''
      const isDown = Number(props.delta) <= 0

      return h('div', { class: ['weight-chart', props.large ? 'large' : '', isDown ? 'is-down' : 'is-up'] }, [
        h('div', { class: 'weight-chart-top' }, [
          h('div', [
            h('span', '趋势曲线'),
            h('strong', `${props.current} kg`)
          ]),
          h('em', isDown ? '下降中' : '上升中')
        ]),
        h('svg', { viewBox: '0 0 360 220', role: 'img', 'aria-label': '体重记录趋势曲线' }, [
          h('defs', [
            h('linearGradient', { id: 'weight-area-gradient', x1: '0', y1: '0', x2: '0', y2: '1' }, [
              h('stop', { offset: '0%', 'stop-color': '#4de4db', 'stop-opacity': '.38' }),
              h('stop', { offset: '100%', 'stop-color': '#caff72', 'stop-opacity': '.04' })
            ]),
            h('linearGradient', { id: 'weight-line-gradient', x1: '24', y1: '40', x2: '336', y2: '160', gradientUnits: 'userSpaceOnUse' }, [
              h('stop', { offset: '0%', 'stop-color': '#11c4ff' }),
              h('stop', { offset: '48%', 'stop-color': '#35dfcf' }),
              h('stop', { offset: '100%', 'stop-color': '#b8fb5b' })
            ]),
            h('filter', { id: 'weight-line-glow', x: '-20%', y: '-50%', width: '140%', height: '200%' }, [
              h('feGaussianBlur', { stdDeviation: '4', result: 'blur' }),
              h('feMerge', [
                h('feMergeNode'),
                h('feMergeNode', { in: 'SourceGraphic' })
              ])
            ])
          ]),
          h('g', { class: 'weight-grid-lines' }, [52, 96, 140, 184].map((y) => (
            h('line', { x1: '24', x2: '336', y1: y, y2: y })
          ))),
          areaPath ? h('path', { class: 'weight-area', d: areaPath }) : null,
          linePath ? h('path', { class: 'weight-line-shadow', d: linePath }) : null,
          linePath ? h('path', { class: 'weight-line', d: linePath, pathLength: '1' }) : null,
          h('g', { class: 'weight-nodes' }, coords.map((point, index) => (
            h('g', { key: `${point.weight}-${index}`, class: index === coords.length - 1 ? 'latest' : '' }, [
              h('circle', { cx: point.x, cy: point.y, r: index === coords.length - 1 ? 6 : 4 }),
              h('text', { x: point.x, y: point.y - 12 }, point.weight)
            ])
          ))),
          h('g', { class: 'weight-axis-labels' }, coords.map((point, index) => (
            h('text', { key: point.label, x: point.x, y: '210' }, point.label || `D${index + 1}`)
          )))
        ])
      ])
    }
  }
})

const FoodLog = defineComponent({
  props: {
    foods: { type: Array, required: true },
    title: { type: String, required: true },
    headline: { type: String, default: '' },
    eyebrow: { type: String, default: '今日明细' }
  },
  emits: ['remove'],
  setup(props, { emit }) {
    return () => h(R6Glass, { className: 'food-log', cornerRadius: 28 }, {
      default: () => [
        h('div', { class: 'card-head' }, [
          h('div', [
            h('p', { class: 'eyebrow' }, props.eyebrow),
            h('h2', props.headline || props.title)
          ]),
          h('span', { class: 'total-pill' }, `${props.foods.length} 项`)
        ]),
        h('div', { class: 'food-list' }, props.foods.length
          ? props.foods.map((item) => {
            const food = normalizeFoodRecord(item)
            return h('div', { class: 'food-row', key: food.id }, [
              h('div', { class: 'food-main' }, [
                h('strong', food.name),
                h('span', `${food.grams}g · ${food.time}`),
                h('small', `${food.sourceLabel || '默认预设'} · 每100g ${food.per100kcal || Math.round((Number(food.kcal || 0) / Math.max(1, Number(food.grams || 100))) * 100)} kcal`)
              ]),
              h('div', { class: 'food-metrics' }, [
                h('em', `${food.kcal} kcal`),
                h('span', `P ${Math.round(Number(food.protein || 0))}g`),
                h('span', `C ${Math.round(Number(food.carbs || 0))}g`),
                h('span', `F ${Math.round(Number(food.fat || 0))}g`)
              ]),
              h('button', {
                type: 'button',
                class: 'delete-action',
                'aria-label': '删除摄入记录',
                onClick: () => emit('remove', food.id)
              }, [h(Trash2, { size: 15 })])
            ])
          })
          : h('p', { class: 'empty-state' }, '今天还没有记录摄入。')
        )
      ]
    })
  }
})

const ExerciseLog = defineComponent({
  props: {
    items: { type: Array, required: true },
    headline: { type: String, default: '' }
  },
  emits: ['remove'],
  setup(props, { emit }) {
    return () => h(R6Glass, { className: 'food-log exercise-log', cornerRadius: 28 }, {
      default: () => [
        h('div', { class: 'card-head' }, [
          h('div', [
            h('p', { class: 'eyebrow' }, '今日运动'),
            h('h2', props.headline || '运动记录')
          ]),
          h('span', { class: 'total-pill' }, `${props.items.length} 项`)
        ]),
        h('div', { class: 'food-list' }, props.items.length
          ? props.items.map((item) => h('div', { class: 'food-row', key: item.id }, [
            h('div', { class: 'food-main' }, [
              h('strong', item.name_zh),
              h('span', `${item.duration} 分钟 · ${item.time}`),
              h('small', `${item.category_zh} · ${item.intensity_zh} · MET ${item.met}`)
            ]),
            h('div', { class: 'food-metrics' }, [
              h('em', `${item.kcal} kcal`),
              h('span', `体重 ${item.weightKg}kg`),
              h('span', `${item.duration} 分钟`)
            ]),
            h('button', {
              type: 'button',
              class: 'delete-action',
              'aria-label': '删除运动记录',
              onClick: () => emit('remove', item.id)
            }, [h(Trash2, { size: 15 })])
          ]))
          : h('p', { class: 'empty-state' }, '今天还没有记录运动。')
        )
      ]
    })
  }
})

const navItems = [
  { key: 'overview', label: '总览', icon: BarChart3 },
  { key: 'intake', label: '运动', icon: Activity },
  { key: 'weight', label: '体重', icon: Scale },
  { key: 'target', label: '目标', icon: Target },
  { key: 'calendar', label: '日历', icon: CalendarDays },
  { key: 'profile', label: '我的', icon: User }
]

const pageHeaders = {
  overview: { kicker: '今天', title: '每日能量控制台' },
  intake: { kicker: '运动', title: '运动消耗记录' },
  weight: { kicker: '体重', title: '体重趋势工作台' },
  target: { kicker: '目标', title: '热量目标策略' },
  calendar: { kicker: '日历', title: '健康日历视图' },
  profile: { kicker: '我的', title: '个人账户中心' }
}

const activityOptions = [
  { value: 'sedentary', label: '久坐少动', factor: 1.2 },
  { value: 'light', label: '轻度活动', factor: 1.375 },
  { value: 'moderate', label: '中度活动', factor: 1.55 },
  { value: 'active', label: '高强度活动', factor: 1.725 },
  { value: 'very_active', label: '运动员级', factor: 1.9 }
]

const foodPresets = [
  { name: '燕麦酸奶碗', grams: 320, kcal: 418, protein: 22, carbs: 54, fat: 11 },
  { name: '鸡胸糙米餐', grams: 460, kcal: 612, protein: 48, carbs: 62, fat: 16 },
  { name: '冰拿铁', grams: 250, kcal: 126, protein: 7, carbs: 13, fat: 5 },
  { name: '蛋白奶昔', grams: 380, kcal: 240, protein: 31, carbs: 18, fat: 4 }
]

const foodLibrary = [
  { id: 'rice', name: '大米饭', alias: ['米饭', '白米饭'], category: '主食', source: '默认预设', kcalPer100g: 116, proteinPer100g: 2.6, carbsPer100g: 25.9, fatPer100g: 0.3 },
  { id: 'sweet-potato', name: '红薯', alias: ['地瓜', '番薯'], category: '主食', source: '默认预设', kcalPer100g: 86, proteinPer100g: 1.5, carbsPer100g: 20.1, fatPer100g: 0.1 },
  { id: 'corn', name: '鲜玉米', alias: ['玉米', '甜玉米'], category: '主食', source: '默认预设', kcalPer100g: 112, proteinPer100g: 3.5, carbsPer100g: 22.8, fatPer100g: 1.4 },
  { id: 'chicken-breast', name: '鸡胸肉', alias: ['鸡胸', '鸡胸排'], category: '蛋白质', source: '默认预设', kcalPer100g: 133, proteinPer100g: 19.4, carbsPer100g: 0, fatPer100g: 5 },
  { id: 'egg', name: '水煮蛋', alias: ['鸡蛋', '蛋'], category: '蛋白质', source: '默认预设', kcalPer100g: 144, proteinPer100g: 13.3, carbsPer100g: 1, fatPer100g: 9.5 },
  { id: 'yogurt', name: '无糖酸奶', alias: ['酸奶', '希腊酸奶'], category: '乳制品', source: '默认预设', kcalPer100g: 63, proteinPer100g: 3.6, carbsPer100g: 5, fatPer100g: 3.2 },
  { id: 'oats', name: '燕麦片', alias: ['燕麦', '即食燕麦'], category: '主食', source: '默认预设', kcalPer100g: 389, proteinPer100g: 16.9, carbsPer100g: 66.3, fatPer100g: 6.9 },
  { id: 'apple', name: '苹果', alias: ['红苹果'], category: '水果', source: '默认预设', kcalPer100g: 53, proteinPer100g: 0.3, carbsPer100g: 14, fatPer100g: 0.2 },
  { id: 'banana', name: '香蕉', alias: ['小香蕉'], category: '水果', source: '默认预设', kcalPer100g: 93, proteinPer100g: 1.1, carbsPer100g: 22.8, fatPer100g: 0.2 },
  { id: 'latte', name: '冰拿铁', alias: ['拿铁', '冰咖啡'], category: '饮品', source: '默认预设', kcalPer100g: 50, proteinPer100g: 2.8, carbsPer100g: 5.2, fatPer100g: 1.9 },
  { id: 'protein-shake', name: '蛋白奶昔', alias: ['奶昔', '蛋白粉'], category: '饮品', source: '默认预设', kcalPer100g: 63, proteinPer100g: 8.2, carbsPer100g: 4.7, fatPer100g: 1 },
  { id: 'broccoli', name: '西兰花', alias: ['花椰菜', '青花菜'], category: '蔬菜', source: '默认预设', kcalPer100g: 34, proteinPer100g: 2.8, carbsPer100g: 6.6, fatPer100g: 0.4 }
]

const activeSection = ref('overview')
const showAuthModal = ref(false)
const showProfileModal = ref(false)
const showAuthorModal = ref(false)
const showInstallGuide = ref(false)
const deferredInstallPrompt = ref(null)
const isStandalonePwa = ref(false)
const isIOS = ref(false)
const authMode = ref('login')
const authLoading = ref(false)
const profileLoading = ref(false)
const authMessage = ref('')
const profileMessage = ref('')
const sessionUser = ref(null)
const foodSearchQuery = ref('')
const foodInputMode = ref('search')
const selectedFoodId = ref('')
const foods = ref([])
const customFoods = ref([])
const weights = ref([])
const weightDraft = ref(72.4)
const profileTouched = ref(false)
const customFoodMessage = ref('')
const customExerciseMessage = ref('')

const profile = reactive({
  sex: 'male',
  age: 29,
  heightCm: 176,
  weightKg: 72.4,
  activity: 'moderate'
})

const authForm = reactive({
  name: '',
  email: '',
  password: ''
})

const goal = reactive({
  mode: 'auto',
  customCalories: 2200
})

const foodDraft = reactive({
  grams: 150
})
const customFoodDraft = reactive({
  name: '',
  kcal: null
})
const miaoFoodLibrary = ref([])
const miaoFoodLibraryMeta = reactive({
  count: 0,
  source: '默认预设'
})
const exerciseSearchQuery = ref('')
const exerciseInputMode = ref('search')
const selectedExerciseId = ref('')
const exerciseCategory = ref('全部')
const exerciseDraft = reactive({
  duration: 30
})
const exercises = ref([])
const customExercises = ref([])
const dailyTargets = ref([])
const customExerciseDraft = reactive({
  name: '',
  kcal: null
})
const sportsList = Array.isArray(sportsLibrary) ? sportsLibrary : (sportsLibrary?.default || [])
const exerciseQuickPicks = sportsList.slice(0, 8)
const calendarMonth = ref(new Date(new Date().getFullYear(), new Date().getMonth(), 1))

const todayLabel = new Intl.DateTimeFormat('zh-CN', {
  month: 'long',
  day: 'numeric',
  weekday: 'long'
}).format(new Date())

const pageHeader = computed(() => pageHeaders[activeSection.value] || pageHeaders.overview)
const installButtonLabel = computed(() => {
  if (isStandalonePwa.value) return ''
  if (isIOS.value && !deferredInstallPrompt.value) return '添加到桌面'
  return '安装APP'
})
const installButtonHint = computed(() => {
  if (isIOS.value && !deferredInstallPrompt.value) return 'iPhone / iPad 使用 Safari 添加'
  return '安装成桌面应用'
})
const accountModeLabel = computed(() => hasSupabaseConfig ? '用户名账户' : '需要配置 Supabase')
const needsProfileSetup = computed(() => Boolean(sessionUser.value && !sessionUser.value.profileComplete))
const selectedActivity = computed(() => activityOptions.find((item) => item.value === profile.activity) || activityOptions[2])
const bodyReadout = computed(() => [
  { label: '年龄', value: `${Number(profile.age || 0)} 岁`, hint: '用于热量公式计算' },
  { label: '身高', value: `${Number(profile.heightCm || 0).toFixed(0)} cm`, hint: '作为基础代谢参数' },
  { label: '体重', value: `${Number(profile.weightKg || 0).toFixed(1)} kg`, hint: '登录后以账户记录为准' }
])
const bmr = computed(() => {
  const sexOffset = profile.sex === 'male' ? 5 : -161
  return 10 * Number(profile.weightKg || 0) + 6.25 * Number(profile.heightCm || 0) - 5 * Number(profile.age || 0) + sexOffset
})
const roundedTdee = computed(() => Math.max(0, Math.round(bmr.value * selectedActivity.value.factor)))
const targetCalories = computed(() => {
  if (goal.mode === 'custom') return Math.round(goal.customCalories || roundedTdee.value)
  if (goal.mode === 'lose') return Math.round(roundedTdee.value * 0.85)
  if (goal.mode === 'gain') return Math.round(roundedTdee.value * 1.1)
  return roundedTdee.value
})
const goalLabel = computed(() => ({
  auto: '自动',
  lose: '减脂',
  maintain: '维持',
  gain: '增肌',
  custom: '自定义'
}[goal.mode] || '自动'))
const todayCalories = computed(() => foods.value.reduce((total, food) => total + Number(food.kcal || 0), 0))
const netCalories = computed(() => todayCalories.value - todayExerciseCalories.value)
const remainingCalories = computed(() => Math.round(targetCalories.value - netCalories.value))
const calorieProgress = computed(() => Math.round((netCalories.value / Math.max(1, targetCalories.value)) * 100))
const calorieRingProgress = computed(() => Math.min(100, Math.max(0, calorieProgress.value)))
const calorieOffset = computed(() => {
  if (calorieRingProgress.value >= 100) return '0'
  if (calorieRingProgress.value <= 0) return '100'
  return (100 - calorieRingProgress.value).toFixed(2)
})
const isOverCalories = computed(() => remainingCalories.value < 0)
const availableFoodLibrary = computed(() => miaoFoodLibrary.value.length ? miaoFoodLibrary.value : foodLibrary)
const selectedFood = computed(() => availableFoodLibrary.value.find((item) => item.id === selectedFoodId.value) || availableFoodLibrary.value[0])
const filteredFoodLibrary = computed(() => {
  const query = foodSearchQuery.value.trim().toLowerCase()
  const list = query
    ? availableFoodLibrary.value.filter((item) => [item.name, item.category, item.categoryCode, ...(item.alias || [])].some((text) => String(text).toLowerCase().includes(query)))
    : availableFoodLibrary.value
  return list.slice(0, 5)
})
const calculatedFood = computed(() => {
  const grams = Math.max(1, Number(foodDraft.grams || 0))
  const food = selectedFood.value
  const ratio = grams / 100
  return {
    kcal: Math.max(0, Math.round(food.kcalPer100g * ratio)),
    protein: Math.max(0, (food.proteinPer100g * ratio).toFixed(1)),
    carbs: Math.max(0, (food.carbsPer100g * ratio).toFixed(1)),
    fat: Math.max(0, (food.fatPer100g * ratio).toFixed(1))
  }
})
const macros = computed(() => {
  const normalized = foods.value.map(normalizeFoodRecord)
  const protein = normalized.reduce((total, food) => total + Number(food.protein || 0), 0)
  const carbs = normalized.reduce((total, food) => total + Number(food.carbs || 0), 0)
  const fat = normalized.reduce((total, food) => total + Number(food.fat || 0), 0)
  const max = Math.max(protein, carbs, fat, 1)
  return [
    { name: '蛋白质', value: Math.round(protein), percent: Math.round((protein / max) * 100) },
    { name: '碳水', value: Math.round(carbs), percent: Math.round((carbs / max) * 100) },
    { name: '脂肪', value: Math.round(fat), percent: Math.round((fat / max) * 100) }
  ]
})
const macrosTotal = computed(() => macros.value.reduce((total, macro) => total + macro.value, 0))
const currentWeight = computed(() => Number(weights.value.at(-1) || profile.weightKg || 0).toFixed(1))
const weightDelta = computed(() => {
  if (weights.value.length < 2) return '0.0'
  return (Number(weights.value.at(-1) || 0) - Number(weights.value[0] || 0)).toFixed(1)
})
const weightDeltaText = computed(() => `${Number(weightDelta.value) >= 0 ? '+' : ''}${weightDelta.value} kg / ${Math.max(1, weights.value.length)}次`)
const averageWeight = computed(() => {
  if (!weights.value.length) return Number(profile.weightKg || 0).toFixed(1)
  const total = weights.value.reduce((sum, weight) => sum + Number(weight || 0), 0)
  return (total / Math.max(1, weights.value.length)).toFixed(1)
})
const weightTrendStatus = computed(() => {
  const delta = Number(weightDelta.value)
  if (delta <= -0.3) return '稳步下降'
  if (delta >= 0.3) return '轻微上升'
  return '保持稳定'
})
const weightPoints = computed(() => {
  const series = weights.value.length ? weights.value : [Number(profile.weightKg || 0)]
  const min = Math.min(...series)
  const max = Math.max(...series)
  return series.map((weight, index) => ({
    weight: Number(weight).toFixed(1),
    height: 24 + ((weight - min) / Math.max(0.1, max - min)) * 70,
    ratio: (weight - min) / Math.max(0.1, max - min),
    label: `${index + 1}`
  }))
})
const weekSummary = computed(() => {
  const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
  return labels.map((label, index) => {
    const kcal = Math.max(900, Math.round(todayCalories.value - 120 + index * 44))
    return {
      label,
      kcal,
      status: kcal > targetCalories.value ? '超出' : kcal > targetCalories.value * 0.85 ? '接近' : '平衡'
    }
  })
})
const calendarWeekdays = ['一', '二', '三', '四', '五', '六', '日']
const calendarMonthLabel = computed(() => new Intl.DateTimeFormat('zh-CN', {
  year: 'numeric',
  month: 'long'
}).format(calendarMonth.value))
const calendarSummaryByDate = computed(() => {
  const foodByDate = new Map()
  const exerciseByDate = new Map()
  const targetByDate = new Map()

  foods.value.forEach((item) => {
    const dateKey = toDateKeyFromTime(item.time, item.date)
    if (!dateKey) return
    foodByDate.set(dateKey, (foodByDate.get(dateKey) || 0) + Number(item.kcal || 0))
  })

  exercises.value.forEach((item) => {
    const dateKey = toDateKeyFromTime(item.time, item.date)
    if (!dateKey) return
    exerciseByDate.set(dateKey, (exerciseByDate.get(dateKey) || 0) + Number(item.kcal || 0))
  })

  dailyTargets.value.forEach((item) => {
    if (!item?.date) return
    targetByDate.set(item.date, Number(item.caloriesKcal || 0))
  })

  return { foodByDate, exerciseByDate, targetByDate }
})
const calendarDays = computed(() => {
  const monthStart = new Date(calendarMonth.value.getFullYear(), calendarMonth.value.getMonth(), 1)
  const monthEnd = new Date(calendarMonth.value.getFullYear(), calendarMonth.value.getMonth() + 1, 0)
  const startOffset = (monthStart.getDay() + 6) % 7
  const gridStart = new Date(monthStart)
  gridStart.setDate(monthStart.getDate() - startOffset)

  const days = []
  const { foodByDate, exerciseByDate, targetByDate } = calendarSummaryByDate.value

  for (let index = 0; index < 42; index += 1) {
    const day = new Date(gridStart)
    day.setDate(gridStart.getDate() + index)
    const dateKey = formatDateKey(day)
    const intake = Math.round(foodByDate.get(dateKey) || 0)
    const exercise = Math.round(exerciseByDate.get(dateKey) || 0)
    const target = Math.round(targetByDate.get(dateKey) || targetCalories.value)
    const remaining = target - intake + exercise
    days.push({
      dateKey,
      dayNumber: day.getDate(),
      isCurrentMonth: day.getMonth() === monthStart.getMonth(),
      isToday: dateKey === todayDate(),
      intake,
      exercise,
      target,
      remaining,
      status: getCalendarStatus(remaining, target, intake)
    })
  }

  return days
})
const calendarRecordedCount = computed(() => calendarDays.value.filter((day) => (
  day.isCurrentMonth && (day.intake > 0 || day.exercise > 0 || calendarSummaryByDate.value.targetByDate.has(day.dateKey))
)).length)
const availableSportsLibrary = computed(() => sportsList)
const exerciseCategoryList = computed(() => {
  const categories = Array.from(new Set(availableSportsLibrary.value.map((item) => item.category_zh).filter(Boolean)))
  return ['全部', ...categories]
})
const filteredSportsLibrary = computed(() => {
  const query = exerciseSearchQuery.value.trim().toLowerCase()
  return availableSportsLibrary.value.filter((item) => {
    const matchesCategory = exerciseCategory.value === '全部' || item.category_zh === exerciseCategory.value
    const matchesQuery = !query || [item.name_zh, item.category_zh, item.intensity_zh, item.source_activity_en].some((text) => String(text).toLowerCase().includes(query))
    return matchesCategory && matchesQuery
  }).slice(0, 10)
})
const selectedExercise = computed(() => availableSportsLibrary.value.find((item) => item.id === selectedExerciseId.value) || filteredSportsLibrary.value[0] || availableSportsLibrary.value[0] || {})
const calculatedExercise = computed(() => {
  const duration = Math.max(5, Number(exerciseDraft.duration || 0))
  const met = Number(selectedExercise.value.met || 0)
  const kcal = Math.max(0, Math.round(met * Number(profile.weightKg || 0) * (duration / 60)))
  return { duration, met: met.toFixed(1), kcal }
})
const todayExerciseCalories = computed(() => exercises.value.reduce((total, item) => total + Number(item.kcal || 0), 0))
const exerciseCount = computed(() => exercises.value.length)
const exercisePeakBurn = computed(() => {
  const values = exercises.value.map((item) => Number(item.kcal || 0))
  return values.length ? Math.max(...values) : 0
})
const exerciseLeadText = computed(() => {
  const diff = todayExerciseCalories.value
  if (!diff) return '选择一个运动，记录后会自动抵扣总览里的剩余热量。'
  if (diff < 150) return '刚刚开始动起来，热量空间会同步增加。'
  if (diff < 400) return '今天的运动已经很不错了，继续保持节奏。'
  return '运动消耗已很可观，总览里的剩余空间会随之变化。'
})
const effectiveCaloriesBudget = computed(() => Math.max(0, remainingCalories.value + todayExerciseCalories.value))
const heroStatusMessage = computed(() => {
  const pools = {
    over: [
      '今天已经超出目标，补一段轻运动会让数字好看很多。',
      '热量有点越线了，晚些时候散步一下就能慢慢拉回来。',
      '这一餐吃得挺尽兴，现在最适合用运动把缺口补回去。',
      '别慌，超出一点并不糟，关键是接下来别继续放飞。',
      '当前是高能量日，控制接下来的摄入会比硬饿自己更有效。'
    ],
    empty: [
      '今天还没开始记录，第一餐记上之后，这里会更像你的私人仪表盘。',
      '当前像一张空白页，记下一次摄入或运动，整天的节奏就会开始成形。',
      '数据还没动起来，先记录一项，系统就能开始给你判断状态。',
      '今天的健康轨迹还没落笔，随手记一餐会很有帮助。',
      '现在空间还满着，等你记录第一条数据后，这里会更有参考价值。'
    ],
    workout: [
      '今天的运动已经开始抵扣摄入，热量空间正在往更舒服的方向走。',
      '你今天不是纯控吃路线，运动贡献已经开始接手一部分压力。',
      '运动数据已经接入，当前剩余空间比静态目标更有弹性。',
      '不错，今天的活动量已经让总览读数更从容了一些。',
      '你不是只在克制饮食，身体活动也在一起帮你平衡。'
    ],
    light: [
      '当前进度很轻，今天还有很充足的调整空间。',
      '现在还是前半段节奏，完全可以从容安排后面的摄入。',
      '热量使用还很保守，今天的余地相当宽松。',
      '目前控制得很稳，后面的餐次可以继续按计划来。',
      '你现在还留着大量空间，整天节奏属于比较轻盈的状态。'
    ],
    balanced: [
      '整体节奏很稳，今天处在一个比较舒服的平衡区间里。',
      '你现在离目标很近，这种状态最适合继续按计划走。',
      '今天的控制感不错，既没有压得太紧，也没有明显放开。',
      '当前属于理想区间，照这个节奏继续就很漂亮。',
      '数据挺顺眼，今天是那种容易收得住的一天。'
    ],
    macro: [
      '热量在看总量，宏量营养在看结构，别忘了顺手也照顾一下蛋白质。',
      '总热量只是表面，真正决定饱腹感的往往是你的宏量分配。',
      '如果后面还要吃，优先补蛋白质会让今天更稳。',
      '数值不只看 kcal，结构合理时整天的状态会明显更轻松。',
      '今天的总量还行，接下来把重点放在更干净的营养结构上会更妙。'
    ]
  }

  let pool = pools.balanced
  if (remainingCalories.value < 0) pool = pools.over
  else if (!todayCalories.value && !todayExerciseCalories.value) pool = pools.empty
  else if (todayExerciseCalories.value >= 120) pool = pools.workout
  else if (calorieProgress.value <= 35) pool = pools.light
  else if (macrosTotal.value <= Math.max(30, todayCalories.value / 20)) pool = pools.macro

  const seed = `${todayDate()}-${goal.mode}-${remainingCalories.value}-${todayCalories.value}-${todayExerciseCalories.value}-${macrosTotal.value}`
  const index = Array.from(seed).reduce((sum, char, idx) => sum + char.charCodeAt(0) * (idx + 1), 0) % pool.length
  return pool[index]
})

function clearPrivateData() {
  foods.value = []
  exercises.value = []
  dailyTargets.value = []
  weights.value = []
  weightDraft.value = Number(profile.weightKg || 72)
}

function markProfileTouched() {
  profileTouched.value = true
}

function shiftCalendarMonth(offset) {
  calendarMonth.value = new Date(
    calendarMonth.value.getFullYear(),
    calendarMonth.value.getMonth() + offset,
    1
  )
}

function cloneProfile() {
  return {
    sex: profile.sex,
    age: Number(profile.age),
    heightCm: Number(profile.heightCm),
    weightKg: Number(profile.weightKg),
    activity: profile.activity
  }
}

function resetAuthForm() {
  authForm.name = ''
  authForm.email = ''
  authForm.password = ''
}

function getSessionToken() {
  return localStorage.getItem(SESSION_TOKEN_KEY) || ''
}

function setSessionToken(token) {
  if (token) localStorage.setItem(SESSION_TOKEN_KEY, token)
  else localStorage.removeItem(SESSION_TOKEN_KEY)
}

function requireSupabase() {
  if (!hasSupabaseConfig || !supabase) {
    throw new Error('请先配置 VITE_SUPABASE_URL 和 VITE_SUPABASE_ANON_KEY，部署后才能使用真实账户系统。')
  }
}

function requireSignedIn() {
  if (!sessionUser.value?.id) {
    openAuth('login')
    throw new Error('请先登录。')
  }
  return getSessionToken()
}

function slugifyUsername(value) {
  return String(value || '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
}

function sanitizeAccountInput(value) {
  return String(value || '').replace(/[^A-Za-z0-9]/g, '')
}

function validateAccountCredentials(username, password) {
  const cleanUsername = sanitizeAccountInput(username)
  const cleanPassword = sanitizeAccountInput(password)
  if (!cleanUsername) throw new Error('请输入用户名，仅支持英文或数字。')
  if (cleanUsername !== String(username || '')) throw new Error('用户名只能包含英文或数字。')
  if (cleanUsername.length < 3 || cleanUsername.length > 24) throw new Error('用户名长度需要在 3 到 24 位之间。')
  if (!cleanPassword) throw new Error('请输入密码，仅支持英文或数字。')
  if (cleanPassword !== String(password || '')) throw new Error('密码只能包含英文或数字。')
  if (cleanPassword.length < 6 || cleanPassword.length > 32) throw new Error('密码长度需要在 6 到 32 位之间。')
}

function randomHex(bytes = 16) {
  const buffer = new Uint8Array(bytes)
  crypto.getRandomValues(buffer)
  return Array.from(buffer, (byte) => byte.toString(16).padStart(2, '0')).join('')
}

function newToken() {
  return `${crypto.randomUUID().replace(/-/g, '')}${randomHex(16)}`
}

function newUserId() {
  return crypto.randomUUID()
}

async function sha256Hex(value) {
  const buffer = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value))
  return Array.from(new Uint8Array(buffer), (byte) => byte.toString(16).padStart(2, '0')).join('')
}

async function passwordHash(password, salt) {
  return sha256Hex(`${password}:${salt}`)
}

function todayRange() {
  const start = new Date()
  start.setHours(0, 0, 0, 0)
  const end = new Date(start)
  end.setDate(end.getDate() + 1)
  return { start: start.toISOString(), end: end.toISOString() }
}

function todayDate() {
  return new Date().toISOString().slice(0, 10)
}

function formatDateKey(value) {
  const date = new Date(value)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function detectStandalonePwa() {
  return window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone === true
}

function detectIOS() {
  return /iphone|ipad|ipod/i.test(navigator.userAgent) && !window.MSStream
}

function handleBeforeInstallPrompt(event) {
  event.preventDefault()
  deferredInstallPrompt.value = event
}

async function handleInstallApp() {
  if (isStandalonePwa.value) return
  if (isIOS.value && !deferredInstallPrompt.value) {
    showInstallGuide.value = true
    return
  }
  if (deferredInstallPrompt.value) {
    const promptEvent = deferredInstallPrompt.value
    deferredInstallPrompt.value = null
    try {
      await promptEvent.prompt()
      const choice = await promptEvent.userChoice
      if (choice?.outcome !== 'accepted') showInstallGuide.value = true
    } catch {
      showInstallGuide.value = true
    }
    return
  }
  showInstallGuide.value = true
}

function toDateKeyFromTime(_time, explicitDate) {
  if (explicitDate) return explicitDate
  return todayDate()
}

function monthRange(baseDate) {
  const start = new Date(baseDate.getFullYear(), baseDate.getMonth(), 1)
  const end = new Date(baseDate.getFullYear(), baseDate.getMonth() + 1, 0)
  return { start: formatDateKey(start), end: formatDateKey(end) }
}

function getCalendarStatus(remaining, target, intake) {
  if (!intake && remaining === target) return '未记录'
  if (remaining < 0) return '超出'
  if (remaining <= Math.max(120, target * 0.12)) return '接近'
  return '平衡'
}

function openAuth(mode) {
  authMode.value = mode
  authMessage.value = ''
  showAuthModal.value = true
}

function closeAuth() {
  showAuthModal.value = false
  authMessage.value = ''
}

function toggleAuthMode() {
  authMode.value = authMode.value === 'login' ? 'register' : 'login'
  authMessage.value = ''
}

async function submitAuth() {
  authLoading.value = true
  authMessage.value = ''
  try {
    requireSupabase()
    await submitSupabaseAuth()
  } catch (error) {
    authMessage.value = error?.message || '账户处理失败，请稍后再试。'
  } finally {
    authLoading.value = false
  }
}

async function submitSupabaseAuth() {
  const rawRegisterName = authForm.name.trim()
  const rawLoginName = (authForm.email || authForm.name).trim()
  const rawPassword = authForm.password
  if (authMode.value === 'register') {
    validateAccountCredentials(rawRegisterName, rawPassword)
    const registerName = sanitizeAccountInput(rawRegisterName)
    authForm.name = registerName
    authForm.password = sanitizeAccountInput(rawPassword)
    const salt = randomHex(16)
    const hash = await passwordHash(authForm.password, salt)
    const token = newToken()
    const userId = newUserId()
    const { data, error } = await supabase.rpc('app_register', {
      p_password_hash: hash,
      p_password_salt: salt,
      p_token: token,
      p_user_id: userId,
      p_display_name: registerName,
      p_username: slugifyUsername(registerName)
    })
    if (error) throw error
    const row = Array.isArray(data) ? data[0] : data
    setSessionToken(row?.token || '')
    sessionUser.value = {
      id: row?.user_id,
      email: '未绑定',
      authEmail: '',
      name: row?.display_name || registerName,
      profileComplete: false,
      isAnonymous: false
    }
    closeAuth()
    resetAuthForm()
    await loadSupabaseAccount({ optionalMonthTargets: true })
    showProfileModal.value = true
    return
  }
  validateAccountCredentials(rawLoginName, rawPassword)
  const loginName = sanitizeAccountInput(rawLoginName)
  authForm.email = loginName
  authForm.password = sanitizeAccountInput(rawPassword)
  const identifier = loginName
  const { data: saltRows, error: saltError } = await supabase.rpc('app_password_salt', {
    p_identifier: identifier
  })
  if (saltError) throw saltError
  const salt = (Array.isArray(saltRows) ? saltRows[0] : saltRows)?.password_salt
  if (!salt) throw new Error('用户名或密码错误。')
  const hash = await passwordHash(authForm.password, salt)
  const token = newToken()
  const { data, error } = await supabase.rpc('app_login', {
    p_identifier: identifier,
    p_password_hash: hash,
    p_token: token
  })
  if (error) throw error
  const row = Array.isArray(data) ? data[0] : data
  setSessionToken(row?.token || '')
  sessionUser.value = {
    id: row?.user_id,
    email: '未绑定',
    authEmail: '',
    name: row?.display_name || row?.username || authForm.email.trim() || 'R6 用户',
    profileComplete: false,
    isAnonymous: false
  }
  closeAuth()
  resetAuthForm()
  await loadSupabaseAccount({ optionalMonthTargets: true })
  showProfileModal.value = !sessionUser.value.profileComplete
}

async function loadSupabaseProfile() {
  const token = getSessionToken()
  if (!token) return
  const { data, error } = await supabase.rpc('app_profile_get', { p_token: token })
  if (error) throw error
  const row = Array.isArray(data) ? data[0] : data
  if (!row) return

  const age = row.birth_date ? Math.max(12, new Date().getFullYear() - new Date(row.birth_date).getFullYear()) : profile.age
  Object.assign(profile, {
    sex: ['female', 'male'].includes(row.sex) ? row.sex : profile.sex,
    age,
    heightCm: Number(row.height_cm || profile.heightCm),
    activity: row.activity_level || profile.activity
  })
  if (row.calorie_goal_kcal) {
    goal.mode = 'custom'
    goal.customCalories = Number(row.calorie_goal_kcal)
  }
  sessionUser.value = {
    ...sessionUser.value,
    name: row.display_name || sessionUser.value.name,
    profileComplete: Boolean(row.height_cm && row.birth_date)
  }
}

async function loadSupabaseAccount(options = {}) {
  requireSupabase()
  await loadSupabaseProfile()
  await Promise.all([
    loadSupabaseFoodLogs(),
    loadSupabaseCustomFoods(),
    loadSupabaseExerciseLogs(),
    loadSupabaseCustomExercises(),
    loadSupabaseWeights(),
    loadSupabaseDailyTarget(),
    options.optionalMonthTargets ? loadSupabaseDailyTargetsForMonthOptional() : loadSupabaseDailyTargetsForMonth()
  ])
}

function handleAccountEntry() {
  if (!sessionUser.value) {
    openAuth('login')
    return
  }
  activeSection.value = 'profile'
}

function openProfileEditor() {
  if (!sessionUser.value) {
    openAuth('login')
    return
  }
  profileMessage.value = ''
  showProfileModal.value = true
}

async function completeProfile() {
  profileLoading.value = true
  profileMessage.value = ''
  try {
    validateProfile()
    if (sessionUser.value) {
      if (hasSupabaseConfig) {
        await saveSupabaseProfile()
        await saveSupabaseWeight(profile.weightKg)
        await loadSupabaseAccount({ optionalMonthTargets: true })
      } else {
        throw new Error('请先配置 Supabase 后再保存真实账户资料。')
      }
      sessionUser.value = { ...sessionUser.value, profileComplete: true }
    }
    weightDraft.value = Number(profile.weightKg)
    profileTouched.value = false
    showProfileModal.value = false
  } catch (error) {
    profileMessage.value = error?.message || '资料保存失败，请检查输入。'
  } finally {
    profileLoading.value = false
  }
}

function validateProfile() {
  if (profile.age < 12 || profile.age > 100) throw new Error('年龄需要在 12 到 100 之间。')
  if (profile.heightCm < 120 || profile.heightCm > 230) throw new Error('身高需要在 120 到 230 cm 之间。')
  if (profile.weightKg < 30 || profile.weightKg > 250) throw new Error('体重需要在 30 到 250 kg 之间。')
}

async function saveSupabaseProfile() {
  const token = getSessionToken()
  const birthYear = new Date().getFullYear() - Number(profile.age)
  const { error } = await supabase.rpc('app_profile_save', {
    p_token: token,
    p_display_name: sessionUser.value.name,
    p_sex: profile.sex,
    p_birth_date: `${birthYear}-01-01`,
    p_height_cm: profile.heightCm,
    p_activity_level: profile.activity,
    p_calorie_goal_kcal: targetCalories.value
  })
  if (error) throw error
}

async function saveSupabaseWeight(value) {
  const token = getSessionToken()
  const { error } = await supabase.rpc('app_weight_save', {
    p_token: token,
    p_weight_kg: Number(value),
    p_logged_on: todayDate()
  })
  if (error) throw error
}

async function saveDailyTarget() {
  const token = requireSignedIn()
  if (!hasSupabaseConfig) throw new Error('请先配置 Supabase 后再保存目标。')
  const { error } = await supabase.rpc('app_target_save', {
    p_token: token,
    p_target_on: todayDate(),
    p_calories_kcal: targetCalories.value,
    p_protein_g: macros.value[0]?.value || 0,
    p_carbs_g: macros.value[1]?.value || 0,
    p_fat_g: macros.value[2]?.value || 0
  })
  if (error) throw error
  await saveSupabaseProfile()
}

function mapFoodLog(row) {
  return {
    id: row.id,
    name: row.food_name,
    date: formatDateKey(row.logged_at),
    grams: Number(row.grams),
    kcal: Math.round(Number(row.calories_kcal || 0)),
    protein: Number(row.protein_g || 0),
    carbs: Number(row.carbs_g || 0),
    fat: Number(row.fat_g || 0),
    time: formatTime(row.logged_at),
    sourceLabel: row.source_label || '默认预设',
    per100kcal: row.per_100_kcal ? Math.round(Number(row.per_100_kcal)) : undefined
  }
}

function mapExerciseLog(row) {
  return {
    id: row.id,
    idRef: row.activity_id,
    date: formatDateKey(row.logged_at),
    name_zh: row.activity_name,
    category_zh: row.category,
    intensity_zh: row.intensity,
    met: Number(row.met || 0).toFixed(1),
    duration: Number(row.duration_min),
    kcal: Math.round(Number(row.calories_kcal || 0)),
    weightKg: Number(row.weight_kg || profile.weightKg).toFixed(1),
    time: formatTime(row.logged_at)
  }
}

async function insertSupabaseFoodLog(token, record) {
  const { data, error } = await supabase.rpc('app_food_add', {
    p_token: token,
    p_food_name: record.name,
    p_grams: record.grams,
    p_calories_kcal: record.kcal,
    p_protein_g: record.protein,
    p_carbs_g: record.carbs,
    p_fat_g: record.fat,
    p_source_label: record.sourceLabel || '默认预设',
    p_per_100_kcal: record.per100kcal
  })
  if (error) throw error
  return mapFoodLog(Array.isArray(data) ? data[0] : data)
}

async function insertSupabaseExerciseLog(token, record) {
  const { data, error } = await supabase.rpc('app_exercise_add', {
    p_token: token,
    p_activity_id: record.idRef,
    p_activity_name: record.name_zh,
    p_category: record.category_zh,
    p_intensity: record.intensity_zh,
    p_met: record.met,
    p_duration_min: record.duration,
    p_calories_kcal: record.kcal,
    p_weight_kg: record.weightKg
  })
  if (error) throw error
  return mapExerciseLog(Array.isArray(data) ? data[0] : data)
}

async function loadSupabaseFoodLogs() {
  const token = getSessionToken()
  const { data, error } = await supabase.rpc('app_food_list', { p_token: token })
  if (error) throw error
  foods.value = (data || []).map(mapFoodLog)
}

async function loadSupabaseCustomFoods() {
  const token = getSessionToken()
  const { data, error } = await supabase.rpc('app_custom_food_list', { p_token: token })
  if (error) throw error
  customFoods.value = (data || []).map((row) => ({
    id: row.id,
    name: row.name,
    kcal: Math.round(Number(row.calories_kcal || 0)),
    createdAt: row.created_at
  }))
}

async function loadSupabaseExerciseLogs() {
  const token = getSessionToken()
  const { data, error } = await supabase.rpc('app_exercise_list', { p_token: token })
  if (error) throw error
  exercises.value = (data || []).map(mapExerciseLog)
}

async function loadSupabaseCustomExercises() {
  const token = getSessionToken()
  const { data, error } = await supabase.rpc('app_custom_exercise_list', { p_token: token })
  if (error) throw error
  customExercises.value = (data || []).map((row) => ({
    id: row.id,
    name_zh: row.activity_name,
    kcal: Math.round(Number(row.calories_30min_70kg || 0)),
    createdAt: row.created_at
  }))
}

async function loadSupabaseWeights() {
  const token = getSessionToken()
  const { data, error } = await supabase.rpc('app_weight_list', { p_token: token })
  if (error) throw error
  const series = (data || []).map((row) => Number(row.weight_kg)).reverse()
  weights.value = series.length ? series : []
  if (series.length) {
    profile.weightKg = series.at(-1)
    weightDraft.value = series.at(-1)
  }
}

async function loadSupabaseDailyTarget() {
  const token = getSessionToken()
  const { data, error } = await supabase.rpc('app_target_get', {
    p_token: token,
    p_target_on: todayDate()
  })
  if (error) throw error
  const row = Array.isArray(data) ? data[0] : data
  if (row?.calories_kcal) {
    goal.mode = 'custom'
    goal.customCalories = Number(row.calories_kcal)
  }
}

async function loadSupabaseDailyTargetsForMonth() {
  const token = getSessionToken()
  const { start, end } = monthRange(calendarMonth.value)
  const { data, error } = await supabase.rpc('app_target_list', {
    p_token: token,
    p_date_from: start,
    p_date_to: end
  })
  if (error) throw error
  dailyTargets.value = (data || []).map((row) => ({
    date: row.target_on,
    caloriesKcal: Number(row.calories_kcal || 0),
    proteinG: Number(row.protein_g || 0),
    fatG: Number(row.fat_g || 0),
    carbsG: Number(row.carbs_g || 0)
  }))
}

async function loadSupabaseDailyTargetsForMonthOptional() {
  try {
    await loadSupabaseDailyTargetsForMonth()
  } catch (error) {
    if (String(error?.message || '').includes('app_target_list')) {
      dailyTargets.value = []
      return
    }
    throw error
  }
}

async function logout() {
  const token = getSessionToken()
  if (hasSupabaseConfig && token) await supabase.rpc('app_logout', { p_token: token })
  setSessionToken('')
  sessionUser.value = null
  clearPrivateData()
  activeSection.value = 'overview'
}

function selectFood(food) {
  selectedFoodId.value = food.id
  foodSearchQuery.value = food.name
  if (!foodDraft.grams) foodDraft.grams = 150
}

function selectExercise(sport) {
  selectedExerciseId.value = sport.id
  exerciseSearchQuery.value = sport.name_zh
  if (!exerciseDraft.duration) exerciseDraft.duration = 30
}

function resetCustomFoodDraft() {
  customFoodDraft.name = ''
  customFoodDraft.kcal = null
}

function resetCustomExerciseDraft() {
  customExerciseDraft.name = ''
  customExerciseDraft.kcal = null
}

async function addFood() {
  if (!selectedFood.value || !foodDraft.grams) return
  const token = requireSignedIn()
  const grams = Math.max(1, Number(foodDraft.grams || 100))
  const record = {
    name: selectedFood.value.name,
    grams,
    kcal: calculatedFood.value.kcal,
    protein: Number(calculatedFood.value.protein),
    carbs: Number(calculatedFood.value.carbs),
    fat: Number(calculatedFood.value.fat),
    time: formatTime(),
    sourceLabel: selectedFood.value.source,
    per100kcal: selectedFood.value.kcalPer100g
  }
  if (hasSupabaseConfig) {
    const saved = await insertSupabaseFoodLog(token, record)
    foods.value.unshift(saved)
  } else {
    foods.value.unshift({ id: Date.now(), ...record })
  }
  foodDraft.grams = 150
  foodSearchQuery.value = ''
}

async function addExercise() {
  if (!selectedExercise.value?.id) return
  const token = requireSignedIn()
  const record = {
    idRef: selectedExercise.value.id,
    name_zh: selectedExercise.value.name_zh,
    category_zh: selectedExercise.value.category_zh,
    intensity_zh: selectedExercise.value.intensity_zh,
    met: calculatedExercise.value.met,
    duration: calculatedExercise.value.duration,
    kcal: calculatedExercise.value.kcal,
    weightKg: Number(profile.weightKg).toFixed(1),
    time: formatTime()
  }
  if (hasSupabaseConfig) {
    const saved = await insertSupabaseExerciseLog(token, record)
    exercises.value.unshift(saved)
  } else {
    exercises.value.unshift({ id: Date.now(), ...record })
  }
  exerciseDraft.duration = 30
  exerciseSearchQuery.value = ''
}

async function saveCustomFood(addToToday) {
  const name = customFoodDraft.name.trim()
  const kcal = Number(customFoodDraft.kcal)
  if (!name || !kcal) return
  const token = requireSignedIn()
  const saved = hasSupabaseConfig
    ? await saveCustomFoodRemote(token, name, kcal)
    : { id: Date.now(), name, kcal }
  if (!customFoods.value.some((item) => item.name === saved.name)) {
    customFoods.value.unshift(saved)
  }
  customFoodMessage.value = addToToday ? `已保存并加入「${saved.name}」` : `已保存「${saved.name}」`
  if (addToToday) {
    await addCustomFoodToToday(saved)
  }
  resetCustomFoodDraft()
}

async function saveCustomFoodRemote(token, name, kcal) {
  const { data, error } = await supabase.rpc('app_custom_food_save', {
    p_token: token,
    p_name: name,
    p_calories_kcal: kcal
  })
  if (error) throw error
  const row = Array.isArray(data) ? data[0] : data
  return {
    id: row?.id || Date.now(),
    name: row?.name || name,
    kcal: Math.round(Number(row?.calories_kcal || kcal)),
    createdAt: row?.created_at
  }
}

async function addCustomFoodToToday(item) {
  const token = requireSignedIn()
  const record = {
    name: item.name,
    grams: 1,
    kcal: Number(item.kcal || 0),
    protein: 0,
    carbs: 0,
    fat: 0,
    time: formatTime(),
    sourceLabel: '我的自定义摄入',
    per100kcal: Number(item.kcal || 0)
  }
  if (hasSupabaseConfig) {
    const saved = await insertSupabaseFoodLog(token, record)
    foods.value.unshift(saved)
  } else {
    foods.value.unshift({ id: Date.now(), ...record })
  }
  customFoodMessage.value = `已加入「${item.name}」到今日摄入`
}

async function removeCustomFood(item) {
  const token = requireSignedIn()
  if (!confirm(`确定删除自定义摄入「${item.name}」吗？`)) return
  try {
    if (hasSupabaseConfig) {
      const { error } = await supabase.rpc('app_custom_food_delete', {
        p_token: token,
        p_id: item.id
      })
      if (error) throw error
    }
    customFoods.value = customFoods.value.filter((entry) => entry.id !== item.id)
    customFoodMessage.value = `已删除「${item.name}」`
  } catch (error) {
    customFoodMessage.value = error?.message || '删除失败，请先在 Supabase 运行最新 schema.sql。'
  }
}

async function saveCustomExercise(addToToday) {
  const name = customExerciseDraft.name.trim()
  const kcal = Number(customExerciseDraft.kcal)
  if (!name || !kcal) return
  const token = requireSignedIn()
  const saved = hasSupabaseConfig
    ? await saveCustomExerciseRemote(token, name, kcal)
    : { id: Date.now(), name_zh: name, kcal }
  if (!customExercises.value.some((item) => item.name_zh === saved.name_zh)) {
    customExercises.value.unshift(saved)
  }
  customExerciseMessage.value = addToToday ? `已保存并记录「${saved.name_zh}」` : `已保存「${saved.name_zh}」`
  if (addToToday) {
    await addCustomExerciseToToday(saved)
  }
  resetCustomExerciseDraft()
}

async function saveCustomExerciseRemote(token, name, kcal) {
  const { data, error } = await supabase.rpc('app_custom_exercise_save', {
    p_token: token,
    p_activity_name: name,
    p_calories_kcal: kcal
  })
  if (error) throw error
  const row = Array.isArray(data) ? data[0] : data
  return {
    id: row?.id || Date.now(),
    name_zh: row?.activity_name || name,
    kcal: Math.round(Number(row?.calories_30min_70kg || kcal)),
    createdAt: row?.created_at
  }
}

async function addCustomExerciseToToday(item) {
  const token = requireSignedIn()
  const record = {
    idRef: `custom-${item.id}`,
    name_zh: item.name_zh,
    category_zh: '自定义',
    intensity_zh: '自定义',
    met: '1.0',
    duration: 30,
    kcal: Number(item.kcal || 0),
    weightKg: Number(profile.weightKg).toFixed(1),
    time: formatTime()
  }
  if (hasSupabaseConfig) {
    const saved = await insertSupabaseExerciseLog(token, record)
    exercises.value.unshift(saved)
  } else {
    exercises.value.unshift({ id: Date.now(), ...record })
  }
  customExerciseMessage.value = `已记录「${item.name_zh}」到今日运动`
}

async function removeCustomExercise(item) {
  const token = requireSignedIn()
  if (!confirm(`确定删除自定义运动「${item.name_zh}」吗？`)) return
  try {
    if (hasSupabaseConfig) {
      const { error } = await supabase.rpc('app_custom_exercise_delete', {
        p_token: token,
        p_id: item.id
      })
      if (error) throw error
    }
    customExercises.value = customExercises.value.filter((entry) => entry.id !== item.id)
    customExerciseMessage.value = `已删除「${item.name_zh}」`
  } catch (error) {
    customExerciseMessage.value = error?.message || '删除失败，请先在 Supabase 运行最新 schema.sql。'
  }
}

async function addPresetFood(preset) {
  const token = requireSignedIn()
  const record = {
    ...preset,
    sourceLabel: '常用模板',
    per100kcal: Math.round((Number(preset.kcal || 0) / Math.max(1, Number(preset.grams || 100))) * 100),
    time: formatTime()
  }
  if (hasSupabaseConfig) {
    const saved = await insertSupabaseFoodLog(token, record)
    foods.value.unshift(saved)
  } else {
    foods.value.unshift({ id: Date.now(), ...record })
  }
}

async function removeFood(id) {
  if (hasSupabaseConfig && sessionUser.value?.id) {
    const { error } = await supabase.rpc('app_food_delete', {
      p_token: getSessionToken(),
      p_id: id
    })
    if (error) throw error
  }
  foods.value = foods.value.filter((food) => food.id !== id)
}

async function removeExercise(id) {
  if (hasSupabaseConfig && sessionUser.value?.id) {
    const { error } = await supabase.rpc('app_exercise_delete', {
      p_token: getSessionToken(),
      p_id: id
    })
    if (error) throw error
  }
  exercises.value = exercises.value.filter((item) => item.id !== id)
}

function normalizeFoodRecord(food) {
  const preset = foodPresets.find((item) => item.name === food.name)
  if (!preset) return food
  return {
    ...food,
    protein: Number(food.protein ?? preset.protein ?? 0),
    carbs: Number(food.carbs ?? preset.carbs ?? 0),
    fat: Number(food.fat ?? preset.fat ?? 0),
    sourceLabel: food.sourceLabel || '常用模板',
    per100kcal: food.per100kcal || Math.round((Number(food.kcal || preset.kcal || 0) / Math.max(1, Number(food.grams || preset.grams || 100))) * 100)
  }
}

async function addWeight() {
  if (!weightDraft.value) return
  const token = requireSignedIn()
  const nextWeight = Number(weightDraft.value)
  if (hasSupabaseConfig) {
    const { error } = await supabase.rpc('app_weight_save', {
      p_token: token,
      p_weight_kg: nextWeight,
      p_logged_on: todayDate()
    })
    if (error) throw error
    await loadSupabaseWeights()
  } else {
    weights.value = [...weights.value.slice(-11), nextWeight]
  }
  profile.weightKg = nextWeight
  profileTouched.value = true
  if (hasSupabaseConfig) await saveSupabaseProfile()
}

function formatTime(value = new Date()) {
  return new Intl.DateTimeFormat('zh-CN', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
  }).format(new Date(value))
}

async function syncState() {
  if (!sessionUser.value?.id) {
    openAuth('login')
    return
  }
  if (!hasSupabaseConfig) {
    authMessage.value = '请先配置 Supabase 后再同步真实账户数据。'
    openAuth('login')
    return
  }
  await Promise.all([
    loadSupabaseFoodLogs(),
    loadSupabaseCustomFoods(),
    loadSupabaseExerciseLogs(),
    loadSupabaseCustomExercises(),
    loadSupabaseWeights(),
    loadSupabaseDailyTarget(),
    loadSupabaseDailyTargetsForMonthOptional()
  ])
}

function persistState() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify({
    activeSection: activeSection.value,
    goal: { mode: goal.mode, customCalories: goal.customCalories }
  }))
}

async function loadBuiltInFoodLibrary() {
  const module = await import('../data/foodLibrary.js')
  miaoFoodLibrary.value = module.foodLibrary || []
  Object.assign(miaoFoodLibraryMeta, module.foodLibraryMeta || {})
  if (!selectedFoodId.value || !availableFoodLibrary.value.some((item) => item.id === selectedFoodId.value)) {
    selectedFoodId.value = availableFoodLibrary.value[0]?.id || ''
  }
}

onMounted(async () => {
  isStandalonePwa.value = detectStandalonePwa()
  isIOS.value = detectIOS()
  window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt)

  const saved = localStorage.getItem(STORAGE_KEY)
  if (saved) {
    try {
      const parsed = JSON.parse(saved)
      if (parsed.activeSection) activeSection.value = parsed.activeSection
      if (parsed.goal) Object.assign(goal, parsed.goal)
    } catch {
      localStorage.removeItem(STORAGE_KEY)
    }
  }

  await loadBuiltInFoodLibrary()
  if (sportsList.length && !selectedExerciseId.value) {
    selectedExerciseId.value = sportsList[0].id
  }

  if (hasSupabaseConfig) {
    const token = getSessionToken()
    if (token) {
      const { data, error } = await supabase.rpc('app_current_user', { p_token: token })
      if (!error && data?.length) {
        const row = data[0]
        sessionUser.value = {
          id: row.user_id,
          email: row.username,
          authEmail: '',
          name: row.display_name,
          profileComplete: false,
          isAnonymous: false
        }
        await loadSupabaseAccount({ optionalMonthTargets: true })
      } else {
        setSessionToken('')
      }
    }
  }

  weightDraft.value = Number(weights.value.at(-1) || profile.weightKg)
})

onBeforeUnmount(() => {
  window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt)
})

watch([activeSection, goal], persistState, { deep: true })
watch(calendarMonth, async () => {
  if (!sessionUser.value?.id || !hasSupabaseConfig) return
  try {
    await loadSupabaseDailyTargetsForMonthOptional()
  } catch {
    // Keep the current month view usable even if the remote refresh fails.
  }
})
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Noto+Sans+SC:wght@400;500;700;900&display=swap');

:global(*) {
  box-sizing: border-box;
}

:global(body),
:global(#app) {
  margin: 0;
  min-width: 320px;
  min-height: 100%;
  overflow-x: hidden;
  background:
    radial-gradient(circle at 12% 8%, rgba(66, 216, 206, .34), transparent 30%),
    radial-gradient(circle at 84% 12%, rgba(128, 238, 174, .34), transparent 30%),
    radial-gradient(circle at 48% 96%, rgba(88, 186, 255, .18), transparent 34%),
    linear-gradient(135deg, #fbfffe 0%, #e7fbf8 48%, #e7f8f0 100%);
}

:global(html) {
  overflow-x: hidden;
  scrollbar-width: thin;
  scrollbar-color: rgba(31, 153, 145, .42) transparent;
}

:global(*) {
  scrollbar-width: thin;
  scrollbar-color: rgba(31, 153, 145, .38) transparent;
}

:global(*::-webkit-scrollbar) {
  width: 10px;
  height: 10px;
}

:global(*::-webkit-scrollbar-track) {
  margin: 8px;
  border-radius: 999px;
  background: rgba(255, 255, 255, .16);
}

:global(*::-webkit-scrollbar-thumb) {
  min-height: 44px;
  border: 3px solid transparent;
  border-radius: 999px;
  background:
    linear-gradient(135deg, rgba(52, 220, 205, .62), rgba(183, 250, 109, .5)) padding-box;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .76),
    0 8px 18px rgba(41, 172, 163, .18);
}

:global(*::-webkit-scrollbar-thumb:hover) {
  background:
    linear-gradient(135deg, rgba(20, 191, 181, .82), rgba(159, 239, 85, .68)) padding-box;
}

:global(*::-webkit-scrollbar-corner) {
  background: transparent;
}

button,
input,
select {
  font: inherit;
}

button {
  cursor: pointer;
}

.care-app {
  position: relative;
  min-height: 100svh;
  min-height: 100dvh;
  display: grid;
  grid-template-columns: 236px minmax(0, 1fr);
  gap: 22px;
  overflow: hidden;
  padding: 22px;
  color: #123c3b;
  font-family: "Noto Sans SC", "Microsoft YaHei", sans-serif;
  background:
    radial-gradient(circle at 12% 8%, rgba(66, 216, 206, .34), transparent 30%),
    radial-gradient(circle at 84% 12%, rgba(128, 238, 174, .34), transparent 30%),
    radial-gradient(circle at 48% 96%, rgba(88, 186, 255, .18), transparent 34%),
    linear-gradient(135deg, #fbfffe 0%, #e7fbf8 48%, #e7f8f0 100%);
}

.ambient,
.ambient span {
  position: absolute;
  pointer-events: none;
}

.ambient {
  inset: 0;
}

.sheet {
  display: block;
  border-radius: 44% 56% 58% 42%;
  filter: blur(1px);
  opacity: .9;
  animation: drift 12s ease-in-out infinite;
}

.sheet-a {
  width: 34vw;
  height: 34vw;
  left: 14vw;
  top: -16vw;
  background: rgba(60, 216, 205, .22);
}

.sheet-b {
  width: 28vw;
  height: 28vw;
  right: -7vw;
  top: 20vh;
  background: rgba(113, 237, 169, .22);
  animation-delay: -4s;
}

.sheet-c {
  width: 24vw;
  height: 24vw;
  left: 44vw;
  bottom: -12vw;
  background: rgba(77, 176, 255, .16);
  animation-delay: -7s;
}

.r6-shell,
:global(.r6-liquid) {
  position: relative;
  z-index: 1;
  width: 100%;
  min-width: 0;
}

.r6-shell {
  transform: none !important;
  animation-name: none;
}

:global(.r6-liquid .glass) {
  width: 100%;
  min-width: 0;
  height: 100%;
  min-height: inherit;
  display: flex !important;
  flex-direction: column;
  align-items: stretch !important;
  gap: 0 !important;
  color: #123c3b;
  border: 1px solid rgba(88, 191, 184, .34);
  outline: 1px solid rgba(255, 255, 255, .62);
  outline-offset: -2px;
  background:
    linear-gradient(145deg, rgba(255, 255, 255, .58), rgba(215, 255, 247, .28)),
    rgba(229, 255, 251, .22);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .92),
    inset 0 -18px 34px rgba(65, 208, 199, .1),
    0 1px 0 rgba(255, 255, 255, .7),
    0 22px 58px rgba(49, 126, 123, .15) !important;
  transition:
    box-shadow .32s ease,
    border-color .32s ease;
}

:global(.r6-liquid .glass__warp) {
  opacity: .72;
}

:global(.r6-shell .bg-black) {
  display: none;
}

:global(.r6-liquid .glass > div:last-child) {
  width: 100%;
  min-width: 0;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  color: inherit;
  font: inherit !important;
  text-shadow: none !important;
}

:global(.r6-shell:not(.side-rail):not(.login-card):not(.profile-modal) .r6-liquid > .glass:hover) {
  border-color: rgba(54, 189, 179, .46);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .94),
    inset 0 -18px 34px rgba(65, 208, 199, .12),
    0 1px 0 rgba(255, 255, 255, .78),
    0 28px 70px rgba(49, 126, 123, .18) !important;
}

.title-fade-enter-active,
.title-fade-leave-active {
  transition:
    opacity .2s ease,
    transform .22s cubic-bezier(.2, .8, .2, 1);
}

.title-fade-enter-from {
  opacity: 0;
  transform: translateY(8px);
}

.title-fade-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}

.modal-rise-enter-active,
.modal-rise-leave-active {
  transition: opacity .22s ease;
}

.modal-rise-enter-from,
.modal-rise-leave-to {
  opacity: 0;
}

.modal-rise-enter-active :deep(.modal-form),
.modal-rise-enter-active :deep(.profile-form),
.modal-rise-leave-active :deep(.modal-form),
.modal-rise-leave-active :deep(.profile-form) {
  transition:
    opacity .28s ease,
    transform .34s cubic-bezier(.2, .8, .2, 1);
}

.modal-rise-enter-from :deep(.modal-form),
.modal-rise-enter-from :deep(.profile-form) {
  opacity: 0;
  transform: translateY(22px) scale(.975);
}

.modal-rise-leave-to :deep(.modal-form),
.modal-rise-leave-to :deep(.profile-form) {
  opacity: 0;
  transform: translateY(10px) scale(.985);
}

.author-modal-enter-active,
.author-modal-leave-active {
  transition: opacity .22s ease;
}

.author-modal-enter-active .author-note,
.author-modal-leave-active .author-note {
  transition:
    opacity .24s ease,
    transform .28s cubic-bezier(.2, .8, .2, 1);
}

.author-modal-enter-from,
.author-modal-leave-to {
  opacity: 0;
}

.author-modal-enter-from .author-note,
.author-modal-leave-to .author-note {
  opacity: 0;
  transform: translateY(14px) scale(.965);
}

:global(.relative) {
  position: relative;
}

:global(.pointer-events-none) {
  pointer-events: none;
}

:global(.bg-black) {
  background: #000;
}

:global(.opacity-0) {
  opacity: 0;
}

:global(.opacity-20) {
  opacity: .2;
}

:global(.opacity-100) {
  opacity: 1;
}

:global(.mix-blend-overlay) {
  mix-blend-mode: overlay;
}

:global(.cursor-pointer) {
  cursor: pointer;
}

:global(.transition-all) {
  transition-property: all;
}

:global(.r6-shell.side-rail .r6-liquid > .glass) {
  min-height: calc(100vh - 44px);
}

:global(.r6-shell.hero-meter .r6-liquid > .glass) {
  display: block !important;
  min-height: 470px;
  overflow: hidden;
}

:global(.r6-shell.hero-meter .r6-liquid > .glass > div:last-child) {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(150px, 180px);
  align-items: center;
  gap: 16px 20px;
  height: 100%;
}

:global(.r6-shell.quick-add .r6-liquid > .glass),
:global(.r6-shell.food-log .r6-liquid > .glass),
:global(.r6-shell.planner-card .r6-liquid > .glass),
:global(.r6-shell.auth-card .r6-liquid > .glass) {
  padding: 20px !important;
}

:global(.r6-shell.hero-meter .r6-liquid > .glass),
:global(.r6-shell.quick-add .r6-liquid > .glass) {
  height: 100%;
}

:global(.r6-shell.hero-meter .r6-liquid),
:global(.r6-shell.quick-add .r6-liquid) {
  height: 100%;
}

:global(.r6-shell.login-card .r6-liquid > .glass) {
  width: min(760px, 100vw - 44px);
  padding: 0 !important;
  border-radius: 38px !important;
  overflow: hidden;
}

:global(.r6-shell.profile-modal .r6-liquid > .glass) {
  width: min(620px, 100vw - 44px);
  border-radius: 34px !important;
}

.side-rail {
  min-height: calc(100vh - 44px);
  position: sticky;
  top: 22px;
  height: calc(100vh - 44px);
}

:global(.r6-shell.side-rail .r6-liquid),
:global(.r6-shell.side-rail .r6-liquid > .glass),
:global(.r6-shell.side-rail .r6-liquid > .glass > div:last-child) {
  height: 100%;
}

.brand,
.topline,
.top-actions,
.card-head,
.metric-row,
.split,
.account-actions {
  display: flex;
  align-items: center;
}

.brand {
  gap: 12px;
  margin-bottom: 28px;
}

.logo-glass {
  position: relative;
  display: grid;
  place-items: center;
  flex: 0 0 auto;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, .82);
  background:
    radial-gradient(circle at 22% 16%, rgba(255, 255, 255, .96), transparent 28%),
    linear-gradient(135deg, rgba(224, 255, 244, .88), rgba(88, 231, 214, .54), rgba(190, 255, 112, .58), rgba(224, 255, 244, .88));
  background-size: 220% 220%;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .9),
    inset 0 -14px 24px rgba(32, 184, 171, .18),
    0 0 0 1px rgba(114, 244, 218, .22),
    0 18px 42px rgba(51, 174, 163, .26),
    0 0 34px rgba(126, 255, 211, .34);
  animation: logoAura 7s ease-in-out infinite;
}

.logo-glass::after {
  content: "";
  position: absolute;
  inset: -24%;
  border-radius: inherit;
  background: linear-gradient(120deg, transparent 18%, rgba(255, 255, 255, .76) 42%, transparent 62%);
  pointer-events: none;
  mix-blend-mode: screen;
  transform: translateX(-68%) rotate(8deg);
  animation: logoSweep 4.8s ease-in-out infinite;
}

.logo-glass img {
  position: relative;
  z-index: 1;
  display: block;
  width: 82%;
  height: 82%;
  object-fit: contain;
  filter: contrast(1.2) saturate(1.25) drop-shadow(0 2px 6px rgba(0, 93, 86, .24));
}

.brand > .logo-glass {
  width: 48px;
  height: 48px;
  border-radius: 18px;
}

.brand strong,
.brand small,
.rail-status strong,
.rail-status span {
  display: block;
}

.brand small,
.rail-status small,
.rail-status span,
.topline p,
.eyebrow,
.hint,
.food-main span,
.food-main small,
.account-summary span,
.profile-intro,
.empty-state {
  color: rgba(32, 91, 89, .68);
}

.side-rail nav {
  display: grid;
  gap: 8px;
  margin-bottom: auto;
}

.side-rail nav button {
  display: flex;
  align-items: center;
  gap: 10px;
  min-height: 46px;
  border: 0;
  border-radius: 16px;
  padding: 0 12px;
  color: rgba(17, 59, 58, .7);
  background: transparent;
  transition:
    transform .22s ease,
    box-shadow .22s ease,
    background .22s ease,
    color .22s ease;
  will-change: transform;
}

.side-rail nav button.active,
.side-rail nav button:hover {
  color: #053c3a;
  background: linear-gradient(135deg, #e4fff9, #76e7df);
  box-shadow: 0 12px 28px rgba(63, 195, 184, .2);
  transform: translateY(-1px);
}

.rail-status {
  position: relative;
  isolation: isolate;
  overflow: hidden;
  margin-top: auto;
  padding: 18px;
  border: 1px solid rgba(25, 154, 146, .34);
  border-radius: 24px;
  color: #063c3a;
  background:
    radial-gradient(circle at 18% 18%, rgba(255, 255, 255, .88), transparent 28%),
    linear-gradient(135deg, rgba(239, 255, 198, .84), rgba(119, 234, 223, .72)),
    rgba(232, 255, 250, .78);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .86),
    inset 0 -18px 28px rgba(18, 163, 154, .1),
    0 16px 34px rgba(24, 138, 131, .16);
}

.rail-status::before {
  content: "";
  position: absolute;
  inset: -34% -58%;
  z-index: -1;
  background:
    conic-gradient(from 120deg, transparent 0 18%, rgba(255, 255, 255, .52) 28%, rgba(126, 246, 229, .35) 42%, transparent 56% 100%);
  opacity: .78;
  animation: railStatusFlow 7s linear infinite;
}

.rail-status::after {
  content: "";
  position: absolute;
  top: 16px;
  right: 16px;
  width: 9px;
  height: 9px;
  border-radius: 999px;
  background: #23dccf;
  box-shadow:
    0 0 0 6px rgba(35, 220, 207, .15),
    0 0 18px rgba(35, 220, 207, .68);
  animation: railStatusPulse 2.4s ease-in-out infinite;
}

.rail-status strong {
  margin: 6px 0 2px;
  font-size: 28px;
  letter-spacing: 0;
}

.install-rail {
  margin-top: 14px;
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 8px;
  width: 100%;
  min-height: 56px;
  padding: 0 14px;
  border: 1px solid transparent;
  border-radius: 999px;
  color: rgba(18, 78, 75, .62);
  text-align: left;
  background: transparent;
  box-shadow: none;
  transition:
    transform .24s ease,
    box-shadow .24s ease,
    border-color .24s ease,
    background-color .24s ease,
    background .24s ease;
}

.install-rail:hover {
  color: #053c3a;
  background:
    linear-gradient(135deg, rgba(229, 255, 125, .64), rgba(106, 229, 219, .58)),
    rgba(255, 255, 255, .28);
  border-color: rgba(255, 255, 255, .62);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .74),
    0 8px 18px rgba(49, 178, 169, .14);
}

.install-rail:active {
  transform: translateY(1px);
}

.install-rail span {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 12px;
  font-weight: 900;
}

.install-rail svg:first-child {
  color: inherit;
}

.install-rail svg:last-child {
  justify-self: end;
}

.rail-status small,
.rail-status span,
.rail-status strong {
  position: relative;
  z-index: 1;
}

.rail-status,
.logo-glass,
.glass-button,
.primary-action,
.secondary-action,
.danger-action,
.quick-add button,
.weight-form button,
.target-form button,
.custom-actions button,
.preset-grid button,
.exercise-quick-grid button,
.result-list button,
.delete-action,
.icon-plain,
.food-row,
.exercise-row,
.week-grid > div,
.body-readout-item,
.target-summary > div,
.metric-row > div,
.hero-macros,
.food-search,
.grams-field,
.mode-switch,
.selected-food,
.custom-item,
.exercise-preview-grid > div,
.exercise-highlight,
.account-summary > div,
.auth-fields label,
.range-field {
  transition:
    transform .24s ease,
    box-shadow .24s ease,
    border-color .24s ease,
    background-color .24s ease,
    background .24s ease;
}

.glass-button:hover,
.primary-action:hover,
.secondary-action:hover,
.danger-action:hover,
.quick-add button:hover,
.weight-form button:hover,
.target-form button:hover,
.custom-actions button:hover,
.preset-grid button:hover,
.exercise-quick-grid button:hover,
.result-list button:hover,
.delete-action:hover,
.icon-plain:hover {
  transform: translateY(-1px);
}

.side-rail nav button:active,
.glass-button:active,
.primary-action:active,
.secondary-action:active,
.danger-action:active,
.quick-add button:active,
.weight-form button:active,
.target-form button:active,
.custom-actions button:active,
.preset-grid button:active,
.exercise-quick-grid button:active,
.result-list button:active,
.delete-action:active,
.icon-plain:active {
  transform: translateY(1px) scale(.99);
}

.main-board {
  position: relative;
  z-index: 1;
  min-width: 0;
}

.topline {
  justify-content: space-between;
  gap: 16px;
  margin: 4px 0 18px;
}

.topline h1 {
  margin: 0;
  font-size: clamp(30px, 4vw, 54px);
  line-height: 1;
}

.topline p,
.eyebrow {
  margin: 0 0 8px;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: .08em;
  text-transform: uppercase;
}

.top-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.glass-button,
.quick-add button,
.weight-form button,
.target-form button,
.primary-action,
.secondary-action,
.danger-action {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  min-height: 42px;
  border: 0;
  border-radius: 999px;
  padding: 0 16px;
  color: #053c3a;
  font-weight: 900;
  background: linear-gradient(135deg, #e7ff82, #68e9de);
  box-shadow: 0 14px 30px rgba(54, 185, 176, .2);
}

.ghost,
.secondary-action {
  background: rgba(255, 255, 255, .62);
  border: 1px solid rgba(55, 141, 136, .16);
  box-shadow: none;
}

.danger-action {
  color: #7f2f31;
  background: rgba(255, 232, 232, .8);
  box-shadow: none;
}

.dashboard-grid,
.feature-grid {
  display: grid;
  gap: 18px;
}

.dashboard-grid {
  grid-template-columns: minmax(0, 1.22fr) minmax(360px, .78fr);
  align-items: stretch;
  grid-auto-rows: 1fr;
}

.feature-grid {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.hero-meter,
.quick-add {
  min-height: 0;
  height: 100%;
}

.meter-copy {
  min-width: 0;
}

.mega-number {
  display: flex;
  align-items: flex-end;
  gap: 12px;
}

.mega-number strong {
  font-size: clamp(72px, 8.4vw, 118px);
  line-height: .82;
}

.mega-number span {
  margin-bottom: 16px;
  color: #168f8a;
  font-weight: 900;
}

.hint {
  max-width: 560px;
  margin: 18px 0 0;
  line-height: 1.8;
}

.ring-wrap {
  display: grid;
  place-items: center end;
  gap: 12px;
}

.svg-ring {
  width: min(100%, 172px);
  aspect-ratio: 1;
  position: relative;
  display: grid;
  place-items: center;
  border-radius: 50%;
  background:
    radial-gradient(circle at 32% 24%, rgba(255, 255, 255, .88), transparent 24%),
    radial-gradient(circle at 50% 55%, rgba(242, 255, 252, .78), rgba(185, 245, 235, .26) 68%, transparent 70%);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .76),
    0 18px 40px rgba(54, 185, 176, .16);
}

.svg-ring svg {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  overflow: visible;
}

.svg-ring-track,
.svg-ring-progress,
.svg-ring-complete {
  fill: none;
  vector-effect: non-scaling-stroke;
}

.svg-ring-track {
  stroke: rgba(31, 119, 115, .12);
  stroke-width: 12;
}

.svg-ring-progress {
  stroke: url(#calorie-ring-gradient);
  stroke-width: 12;
  stroke-linecap: round;
  stroke-dasharray: 100;
  stroke-dashoffset: var(--offset);
  filter: url(#calorie-ring-glow);
  transition: stroke-dashoffset .7s cubic-bezier(.22, 1, .36, 1);
  transform: rotate(-90deg);
  transform-origin: 80px 80px;
}

.svg-ring-progress.empty {
  opacity: 0;
}

.svg-ring-progress.full {
  opacity: 0;
  transition: opacity .2s ease;
}

.svg-ring-complete {
  stroke: url(#calorie-ring-gradient);
  stroke-width: 12;
  stroke-linecap: round;
  filter: url(#calorie-ring-glow);
}

.ring-wrap.is-over .svg-ring {
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .78),
    0 18px 42px rgba(32, 194, 178, .22);
}

.calorie-alert {
  justify-self: end;
  margin: 0;
  max-width: 210px;
  padding: 9px 13px;
  border: 1px solid rgba(36, 176, 158, .2);
  border-radius: 999px;
  background: linear-gradient(135deg, rgba(237, 255, 251, .82), rgba(198, 250, 238, .46));
  color: #0a7169;
  font-size: 13px;
  font-weight: 700;
  line-height: 1.35;
  text-align: center;
  box-shadow: 0 12px 24px rgba(58, 185, 167, .12);
  backdrop-filter: blur(14px);
}

.ring-core {
  position: relative;
  z-index: 1;
  width: 66%;
  height: 66%;
  display: grid;
  place-items: center;
  align-content: center;
  border-radius: 50%;
  background:
    radial-gradient(circle at 34% 28%, rgba(255, 255, 255, .96), transparent 22%),
    radial-gradient(circle at 50% 58%, rgba(238, 254, 251, .94) 0 64%, rgba(207, 243, 238, .72) 66%, transparent 67%);
}

.ring-core strong {
  color: #0d5c59;
  font-size: clamp(28px, 3vw, 36px);
  line-height: 1;
}

.ring-core small {
  margin-top: 8px;
  color: rgba(21, 91, 87, .62);
  font-size: 12px;
}

.metric-row {
  grid-column: 1 / -1;
  gap: 10px;
}

.hero-macros {
  grid-column: 1 / -1;
  display: grid;
  gap: 8px;
  padding: 12px 14px;
  border: 1px solid rgba(55, 141, 136, .14);
  border-radius: 20px;
  background: rgba(255, 255, 255, .42);
}

.hero-macros-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.hero-macros-head span,
.hero-macros-head strong {
  display: block;
}

.hero-macros-head span {
  color: rgba(32, 91, 89, .62);
  font-size: 12px;
  font-weight: 900;
}

.hero-macros-head strong {
  color: #0d5c59;
  font-size: 18px;
}

.hero-macro-stack {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 8px;
}

.hero-macro-stack div {
  position: relative;
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 8px;
  padding-bottom: 12px;
}

.hero-macro-stack span,
.hero-macro-stack strong {
  display: block;
}

.hero-macro-stack span {
  color: rgba(32, 91, 89, .62);
  font-size: 12px;
}

.hero-macro-stack strong {
  color: #123c3b;
  font-size: 14px;
}

.hero-macro-stack i {
  position: absolute;
  left: 0;
  bottom: 0;
  height: 7px;
  border-radius: 999px;
  background: linear-gradient(90deg, #b7f45f, #4fd8d1);
}

.hero-macro-stack div::after {
  content: "";
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  height: 7px;
  border-radius: 999px;
  background: rgba(42, 139, 133, .1);
  z-index: -1;
}

.hero-status-line {
  grid-column: 1 / -1;
  display: grid;
  gap: 6px;
  padding: 14px 16px;
  border: 1px solid rgba(55, 141, 136, .14);
  border-radius: 18px;
  background:
    linear-gradient(135deg, rgba(255, 255, 255, .54), rgba(222, 255, 249, .38)),
    rgba(255, 255, 255, .4);
}

.hero-status-line span {
  color: rgba(32, 91, 89, .58);
  font-size: 12px;
  font-weight: 900;
}

.hero-status-line p {
  margin: 0;
  color: #0f5f5c;
  font-size: 14px;
  line-height: 1.7;
  font-weight: 700;
}

.metric-row div,
.target-summary div,
.week-grid div,
.account-summary div {
  flex: 1;
  padding: 14px;
  border: 1px solid rgba(55, 141, 136, .16);
  border-radius: 18px;
  background: rgba(255, 255, 255, .5);
}

.body-readout {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}

.body-readout-item {
  padding: 14px;
  border: 1px solid rgba(55, 141, 136, .16);
  border-radius: 18px;
  background: rgba(255, 255, 255, .5);
}

.body-readout-item span,
.body-readout-item strong,
.body-readout-item small {
  display: block;
}

.body-readout-item span,
.body-readout-item small,
.profile-readonly-note {
  color: rgba(32, 91, 89, .62);
}

.body-readout-item strong {
  margin-top: 6px;
  color: #0d5c59;
  font-size: 22px;
  font-weight: 900;
}

.body-readout-item small {
  margin-top: 8px;
  line-height: 1.6;
}

.profile-readonly-note {
  margin: 14px 0 0;
  line-height: 1.7;
}

.target-summary-copy {
  margin: -4px 0 14px;
  color: rgba(32, 91, 89, .68);
  font-size: 13px;
  line-height: 1.7;
}

.calendar-studio {
  min-height: 560px;
}

.calendar-nav {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.calendar-summary-strip {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 10px;
  margin-bottom: 18px;
}

.calendar-summary-strip > div {
  padding: 14px;
  border: 1px solid rgba(55, 141, 136, .14);
  border-radius: 18px;
  background: rgba(255, 255, 255, .48);
}

.calendar-summary-strip span,
.calendar-summary-strip strong {
  display: block;
}

.calendar-summary-strip span {
  color: rgba(32, 91, 89, .6);
  font-size: 12px;
}

.calendar-summary-strip strong {
  margin-top: 6px;
  color: #0d5c59;
  font-size: 24px;
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, minmax(0, 1fr));
  gap: 10px;
}

.calendar-weekday {
  padding: 0 6px 4px;
  color: rgba(32, 91, 89, .56);
  font-size: 12px;
  font-weight: 900;
  text-align: center;
}

.calendar-day {
  min-height: 108px;
  display: grid;
  align-content: space-between;
  justify-items: start;
  gap: 8px;
  padding: 12px;
  border: 1px solid rgba(55, 141, 136, .14);
  border-radius: 20px;
  text-align: left;
  background: rgba(255, 255, 255, .52);
}

.calendar-day small,
.calendar-day strong,
.calendar-day span {
  display: block;
}

.calendar-day small,
.calendar-day span {
  color: rgba(32, 91, 89, .58);
}

.calendar-day strong {
  color: #0d5c59;
  font-size: 24px;
  line-height: 1;
}

.calendar-day span {
  font-size: 12px;
  font-weight: 800;
}

.calendar-day.is-muted {
  opacity: .42;
}

.calendar-day.is-today {
  border-color: rgba(53, 206, 191, .38);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .82),
    0 14px 30px rgba(53, 206, 191, .12);
}

.calendar-day.is-over strong,
.calendar-day.is-over span {
  color: #0f8a83;
}

.metric-row span,
.metric-row strong,
.macro-stack span,
.macro-stack strong,
.target-summary span,
.target-summary strong,
.week-grid span,
.week-grid strong,
.week-grid small,
.account-summary span,
.account-summary strong {
  display: block;
}

.metric-row span,
.target-summary span,
.week-grid span,
.week-grid small {
  color: rgba(32, 91, 89, .62);
  font-size: 12px;
}

.metric-row strong,
.target-summary strong {
  margin-top: 4px;
  font-size: 24px;
}

.quick-add,
.food-log,
.planner-card {
  min-width: 0;
}

.food-log {
  grid-column: 1 / -1;
}

.planner-card {
  min-height: 420px;
}

.wide-feature {
  grid-column: 1 / -1;
}

.card-head {
  justify-content: space-between;
  gap: 14px;
  margin-bottom: 18px;
}

.card-head h2 {
  margin: 0;
  font-size: 24px;
}

.form-grid,
.target-form,
.add-form,
.macro-stack,
.food-list,
.account-summary {
  display: grid;
  gap: 10px;
}

.add-form {
  grid-template-rows: auto auto auto 1fr auto;
  height: 100%;
}

.quick-add .add-form {
  min-height: calc(100% - 66px);
}

.form-grid {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

label {
  display: grid;
  gap: 8px;
  padding: 12px;
  border: 1px solid rgba(55, 141, 136, .15);
  border-radius: 16px;
  background: rgba(255, 255, 255, .54);
  transition:
    border-color .22s ease,
    box-shadow .22s ease,
    background .22s ease;
}

label:focus-within,
.food-search:focus-within {
  border-color: rgba(31, 188, 178, .48);
  background: rgba(255, 255, 255, .76);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .84),
    0 0 0 4px rgba(91, 232, 218, .16),
    0 14px 30px rgba(34, 149, 142, .1);
}

.grams-field:focus-within .grams-slider::-webkit-slider-thumb {
  box-shadow:
    0 8px 18px rgba(35, 172, 162, .3),
    0 0 0 7px rgba(91, 232, 218, .18);
}

.grams-field:focus-within .grams-control input {
  color: #096662;
}

label span {
  color: rgba(32, 91, 89, .62);
  font-size: 12px;
}

.span-2 {
  grid-column: span 2;
}

input,
select {
  width: 100%;
  min-width: 0;
  border: 0;
  outline: 0;
  color: #113b3a;
  background: transparent;
  font-weight: 900;
}

.food-search,
.grams-field,
.weight-form input {
  min-height: 46px;
  padding: 0 14px;
  border: 1px solid rgba(55, 141, 136, .16);
  border-radius: 16px;
  background: rgba(255, 255, 255, .58);
}

.food-search {
  display: flex;
  align-items: center;
  gap: 10px;
  color: #15847f;
}

.mode-switch {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 8px;
  padding: 6px;
  border: 1px solid rgba(55, 141, 136, .13);
  border-radius: 999px;
  background: rgba(255, 255, 255, .5);
}

.mode-switch button {
  min-height: 40px;
  border: 0;
  border-radius: 999px;
  color: rgba(17, 59, 58, .68);
  background: transparent;
  box-shadow: none;
}

.mode-switch button.active {
  color: #053c3a;
  background: linear-gradient(135deg, #e7ff82, #68e9de);
  box-shadow: 0 12px 24px rgba(54, 185, 176, .16);
}

.mode-switch button:hover:not(.active) {
  color: #0b5653;
  background: rgba(255, 255, 255, .58);
}

.quick-add button,
.weight-form button,
.target-form button,
.custom-actions button {
  min-height: 46px;
  border-radius: 16px;
}

.result-list {
  display: grid;
  gap: 8px;
  max-height: 142px;
  overflow: auto;
  padding: 0 10px 0 0;
  scrollbar-gutter: stable;
}

.result-list button {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 10px;
  min-height: 58px;
  border: 1px solid rgba(55, 141, 136, .14);
  border-radius: 16px;
  padding: 10px 12px;
  color: #123c3b;
  text-align: left;
  background: rgba(255, 255, 255, .5);
  box-shadow: none;
}

.result-list button.selected {
  border-color: rgba(32, 176, 166, .42);
  background: linear-gradient(135deg, rgba(229, 255, 251, .92), rgba(188, 255, 232, .62));
}

.result-list button:hover,
.custom-item:hover,
.preset-grid button:hover,
.exercise-quick-grid button:hover,
:global(.r6-shell.food-log .food-row:hover),
.food-row:hover,
.week-grid > div:hover,
.account-summary > div:hover,
.body-readout-item:hover,
.target-summary > div:hover,
.metric-row > div:hover,
.exercise-preview-grid div:hover {
  transform: translateY(-2px);
  border-color: rgba(36, 174, 165, .34);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .82),
    0 16px 34px rgba(42, 138, 132, .12);
}

.result-list button:nth-child(1),
.custom-item:nth-child(1),
.food-row:nth-child(1) {
  animation-delay: .02s;
}

.result-list button:nth-child(2),
.custom-item:nth-child(2),
.food-row:nth-child(2) {
  animation-delay: .05s;
}

.result-list button:nth-child(3),
.custom-item:nth-child(3),
.food-row:nth-child(3) {
  animation-delay: .08s;
}

.result-list button:nth-child(4),
.custom-item:nth-child(4),
.food-row:nth-child(4) {
  animation-delay: .11s;
}

.result-list span,
.result-list strong,
.result-list small {
  display: block;
}

.result-list button span {
  min-width: 0;
}

.result-list button strong {
  white-space: nowrap;
}

.result-list small {
  margin-top: 4px;
  color: rgba(32, 91, 89, .56);
  font-size: 11px;
}

.result-list em {
  flex: 0 0 auto;
  color: #128b86;
  font-size: 12px;
  font-style: normal;
  font-weight: 900;
  white-space: nowrap;
}

.selected-food {
  display: grid;
  grid-template-columns: 1fr;
  gap: 12px;
  padding: 14px;
  border: 1px solid rgba(55, 141, 136, .15);
  border-radius: 22px;
  background:
    linear-gradient(145deg, rgba(255, 255, 255, .68), rgba(230, 255, 250, .5)),
    rgba(255, 255, 255, .48);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, .76);
}

.selected-food span,
.selected-food small,
.grams-field span {
  color: rgba(32, 91, 89, .62);
  font-size: 12px;
}

.selected-food strong,
.selected-food small,
.grams-field span {
  display: block;
}

.selected-food strong {
  margin: 4px 0;
  font-size: 18px;
}

.grams-field {
  display: grid;
  grid-template-columns: 1fr;
  gap: 12px;
  padding: 0;
  border: 0;
  border-radius: 0;
  background: transparent;
  box-shadow: none;
}

.grams-field > * {
  min-width: 0;
}

.grams-topline {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  grid-column: 1 / -1;
  align-items: stretch;
  gap: 10px;
}

.grams-meta {
  display: grid;
  grid-template-rows: auto 1fr;
  min-width: 0;
  min-height: 78px;
  gap: 8px;
  align-items: center;
  padding: 12px;
  border: 1px solid rgba(55, 141, 136, .12);
  border-radius: 18px;
  background: rgba(255, 255, 255, .5);
}

.grams-meta-input {
  justify-items: start;
  text-align: left;
}

.grams-meta-kcal {
  justify-items: start;
  text-align: left;
}

.grams-control {
  display: inline-grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: baseline;
  gap: 4px;
  width: 100%;
  min-height: 34px;
}

.grams-control input {
  width: 100%;
  min-width: 0;
  min-height: 34px;
  color: #074845;
  font-size: clamp(24px, 4.2vw, 34px);
  line-height: 1;
  letter-spacing: 0;
  text-align: left;
  appearance: textfield;
}

.grams-control input::-webkit-outer-spin-button,
.grams-control input::-webkit-inner-spin-button {
  appearance: none;
  margin: 0;
}

.grams-control em {
  color: rgba(11, 86, 82, .62);
  font-style: normal;
  font-size: 18px;
  font-weight: 900;
  line-height: 1;
}

.grams-meta span {
  color: rgba(32, 91, 89, .56);
  font-size: 12px;
  font-weight: 800;
}

.grams-slider {
  grid-column: 1 / -1;
  width: 100%;
  height: 22px;
  padding: 0;
  cursor: grab;
  appearance: none;
  background: transparent;
}

.grams-slider:active {
  cursor: grabbing;
}

.grams-slider::-webkit-slider-runnable-track {
  height: 8px;
  border-radius: 999px;
  background:
    linear-gradient(90deg, #cfff64 0 var(--fill), #5be7d9 var(--fill), rgba(180, 223, 217, .34) var(--fill) 100%);
  box-shadow: inset 0 1px 2px rgba(9, 76, 72, .12);
}

.grams-slider::-webkit-slider-thumb {
  width: 22px;
  height: 22px;
  margin-top: -7px;
  border: 3px solid rgba(255, 255, 255, .92);
  border-radius: 999px;
  appearance: none;
  background: linear-gradient(135deg, #f4ff9b, #39dbc9);
  box-shadow:
    0 8px 18px rgba(35, 172, 162, .3),
    0 0 0 5px rgba(91, 232, 218, .14);
}

.grams-slider::-moz-range-track {
  height: 8px;
  border-radius: 999px;
  background: rgba(180, 223, 217, .34);
}

.grams-slider::-moz-range-progress {
  height: 8px;
  border-radius: 999px;
  background: linear-gradient(90deg, #cfff64, #5be7d9);
}

.grams-slider::-moz-range-thumb {
  width: 18px;
  height: 18px;
  border: 3px solid rgba(255, 255, 255, .92);
  border-radius: 999px;
  background: linear-gradient(135deg, #f4ff9b, #39dbc9);
  box-shadow: 0 8px 18px rgba(35, 172, 162, .3);
}

.inline-kcal {
  display: inline-grid;
  grid-template-columns: auto auto;
  align-items: baseline;
  justify-content: start;
  gap: 4px;
  min-height: 34px;
  color: rgba(20, 88, 84, .64);
  font-size: 13px;
  font-weight: 800;
  text-align: left;
  white-space: nowrap;
}

.inline-kcal strong {
  color: #0d5c59;
  font-size: clamp(24px, 4.2vw, 34px);
  line-height: 1;
}

.custom-entry-form {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 160px;
  gap: 10px;
}

.custom-actions {
  grid-column: 1 / -1;
  display: grid;
  grid-template-columns: .82fr 1.18fr;
  gap: 10px;
}

.custom-actions button {
  min-height: 48px;
  border: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  color: #053c3a;
  font-weight: 900;
  background: linear-gradient(135deg, #e7ff82, #68e9de);
  box-shadow: 0 14px 30px rgba(54, 185, 176, .2);
}

.custom-actions .secondary-action {
  border: 1px solid rgba(55, 141, 136, .16);
  background: rgba(255, 255, 255, .62);
  box-shadow: none;
}

.custom-list {
  display: grid;
  gap: 8px;
  max-height: 214px;
  overflow: auto;
  padding-right: 6px;
}

.custom-list .custom-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  min-height: 62px;
  padding: 12px 14px;
  border: 1px solid rgba(55, 141, 136, .14);
  border-radius: 18px;
  color: #123c3b;
  text-align: left;
  background: linear-gradient(145deg, rgba(255, 255, 255, .74), rgba(220, 255, 248, .42));
  box-shadow: none;
}

.custom-list span,
.custom-list strong,
.custom-list small {
  display: block;
}

.custom-list small {
  margin-top: 4px;
  color: rgba(32, 91, 89, .58);
  font-size: 12px;
}

.custom-list em {
  flex: 0 0 auto;
  color: #0b7772;
  font-style: normal;
  font-weight: 900;
}

.delete-preset {
  flex: 0 0 auto;
  min-height: 34px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 5px;
  border: 1px solid rgba(55, 141, 136, .14);
  border-radius: 999px;
  padding: 0 10px;
  color: #8a3030;
  background: rgba(255, 235, 235, .76);
  box-shadow: none;
  font-size: 12px;
  font-weight: 900;
}

.delete-preset svg {
  flex: 0 0 auto;
  color: currentColor;
  stroke-width: 2.4;
}

.add-preset {
  flex: 0 0 auto;
  min-height: 34px;
  border: 0;
  border-radius: 999px;
  padding: 0 12px;
  color: #073f3d;
  background: linear-gradient(135deg, #e7ff82, #68e9de);
  font-size: 12px;
  font-weight: 900;
  box-shadow: 0 10px 20px rgba(54, 185, 176, .16);
}

.inline-feedback {
  margin: 0;
  min-height: 34px;
  display: inline-flex;
  align-items: center;
  width: fit-content;
  max-width: 100%;
  padding: 0 13px;
  border: 1px solid rgba(36, 176, 158, .18);
  border-radius: 999px;
  color: #0a7169;
  background: linear-gradient(135deg, rgba(237, 255, 251, .82), rgba(198, 250, 238, .46));
  font-size: 13px;
  font-weight: 800;
}

.exercise-form {
  display: grid;
  grid-template-rows: auto auto auto minmax(150px, 1fr) auto auto auto;
  gap: 12px;
  height: 100%;
}

.category-pills {
  display: flex;
  gap: 8px;
  overflow: auto;
  padding: 0 2px 8px 0;
  scrollbar-gutter: stable;
}

.category-pills button {
  flex: 0 0 auto;
  min-height: 34px;
  padding: 0 14px;
  border: 1px solid rgba(55, 141, 136, .14);
  border-radius: 999px;
  background: rgba(255, 255, 255, .54);
  color: rgba(17, 59, 58, .74);
  font-weight: 800;
}

.category-pills button.active {
  color: #0a5653;
  background: linear-gradient(135deg, rgba(228, 255, 249, .96), rgba(118, 231, 223, .72));
  box-shadow: 0 12px 26px rgba(63, 195, 184, .14);
}

.exercise-results {
  max-height: 240px;
}

.exercise-preview-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 8px;
}

.exercise-preview-grid div,
.exercise-highlight {
  padding: 12px;
  border: 1px solid rgba(55, 141, 136, .14);
  border-radius: 18px;
  background: rgba(255, 255, 255, .52);
}

.exercise-preview-grid span,
.exercise-preview-grid strong,
.exercise-preview-grid small {
  display: block;
}

.exercise-preview-grid span,
.exercise-preview-grid small {
  color: rgba(32, 91, 89, .58);
  font-size: 11px;
}

.exercise-preview-grid strong {
  margin-top: 4px;
  color: #0d5c59;
  font-size: 22px;
}

.duration-tile label {
  display: inline-grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: baseline;
  gap: 4px;
  margin-top: 4px;
  padding: 0;
  border: 0;
  border-radius: 0;
  background: transparent;
}

.duration-tile input {
  min-width: 0;
  color: #0d5c59;
  font-size: 22px;
  line-height: 1;
  appearance: textfield;
}

.duration-tile input::-webkit-outer-spin-button,
.duration-tile input::-webkit-inner-spin-button {
  appearance: none;
  margin: 0;
}

.duration-tile label small {
  color: rgba(32, 91, 89, .58);
  font-size: 11px;
  font-weight: 800;
}

.exercise-summary-card {
  min-height: 420px;
}

.exercise-highlight {
  display: grid;
  gap: 14px;
  margin-top: 14px;
}

.exercise-highlight p {
  margin: 0;
  color: rgba(18, 60, 59, .78);
  line-height: 1.7;
}

.exercise-quick-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
}

.exercise-quick-grid button {
  display: block;
  min-height: 86px;
  padding: 14px;
  border: 1px solid rgba(55, 141, 136, .14);
  border-radius: 18px;
  text-align: left;
  background: linear-gradient(145deg, rgba(255, 255, 255, .76), rgba(217, 252, 246, .42));
}

.exercise-form > button {
  width: 100%;
  min-height: 52px;
  border: 1px solid rgba(55, 141, 136, .18);
  border-radius: 18px;
  background: linear-gradient(135deg, rgba(235, 255, 248, .96), rgba(175, 245, 207, .72));
  box-shadow: 0 14px 28px rgba(63, 195, 184, .14);
}

.exercise-quick-grid strong,
.exercise-quick-grid span {
  display: block;
}

.exercise-quick-grid span {
  margin-top: 8px;
  color: rgba(32, 91, 89, .62);
  font-size: 12px;
}

.weight-studio {
  min-height: 560px;
}

.weight-head h2 {
  letter-spacing: 0;
}

.weight-status-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 10px;
  margin: 18px 0 16px;
}

.weight-status-grid div {
  min-height: 74px;
  padding: 14px;
  border: 1px solid rgba(34, 164, 154, .14);
  border-radius: 20px;
  background:
    linear-gradient(145deg, rgba(255, 255, 255, .76), rgba(217, 252, 246, .42));
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, .72);
}

.weight-status-grid span {
  display: block;
  color: rgba(32, 91, 89, .58);
  font-size: 12px;
  font-weight: 800;
}

.weight-status-grid strong {
  display: block;
  margin-top: 9px;
  color: #0a5653;
  font-size: 20px;
  line-height: 1.1;
}

:global(.weight-chart) {
  position: relative;
  min-height: 300px;
  padding: 18px 16px 12px;
  border: 1px solid rgba(28, 158, 151, .14);
  border-radius: 28px;
  overflow: hidden;
  background:
    radial-gradient(circle at 16% 18%, rgba(255, 255, 255, .92), transparent 24%),
    linear-gradient(145deg, rgba(235, 255, 251, .74), rgba(195, 246, 239, .38));
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .8),
    0 20px 40px rgba(45, 177, 165, .12);
}

:global(.weight-chart::after) {
  content: "";
  position: absolute;
  width: 170px;
  height: 170px;
  right: -64px;
  top: -74px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(193, 255, 105, .26), transparent 68%);
  pointer-events: none;
}

:global(.weight-chart-top) {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 14px;
  margin-bottom: 4px;
}

:global(.weight-chart-top span) {
  display: block;
  color: rgba(32, 91, 89, .58);
  font-size: 12px;
  font-weight: 900;
}

:global(.weight-chart-top strong) {
  display: block;
  margin-top: 3px;
  color: #0a5653;
  font-size: 28px;
}

:global(.weight-chart-top em) {
  padding: 7px 12px;
  border-radius: 999px;
  color: #06716a;
  background: rgba(199, 255, 238, .72);
  font-size: 12px;
  font-style: normal;
  font-weight: 900;
}

:global(.weight-chart svg) {
  position: relative;
  z-index: 1;
  width: 100%;
  height: 248px;
  overflow: visible;
}

:global(.weight-chart path),
:global(.weight-chart line),
:global(.weight-chart circle),
:global(.weight-chart text) {
  vector-effect: non-scaling-stroke;
}

:global(.weight-chart path) {
  fill: none;
}

:global(.weight-grid-lines line) {
  stroke: rgba(28, 112, 108, .1);
  stroke-width: 1;
  stroke-dasharray: 4 8;
}

:global(.weight-area) {
  fill: url(#weight-area-gradient) !important;
  stroke: none;
}

:global(.weight-line-shadow),
:global(.weight-line) {
  fill: none;
  stroke-linecap: round;
  stroke-linejoin: round;
}

:global(.weight-line-shadow) {
  stroke: rgba(58, 213, 198, .22);
  stroke-width: 15;
  filter: blur(2px);
}

:global(.weight-line) {
  stroke: url(#weight-line-gradient);
  stroke-width: 6;
  filter: url(#weight-line-glow);
  stroke-dasharray: 1;
  stroke-dashoffset: 1;
  animation: draw-weight-line 1.15s cubic-bezier(.22, 1, .36, 1) forwards;
}

:global(.weight-nodes circle) {
  fill: #f4fffb;
  stroke: #35dfcf;
  stroke-width: 3;
  filter: drop-shadow(0 6px 10px rgba(31, 177, 165, .22));
}

:global(.weight-nodes .latest circle) {
  fill: #caff72;
  stroke: #14c7bb;
}

:global(.weight-nodes text),
:global(.weight-axis-labels text) {
  text-anchor: middle;
  font-weight: 800;
  fill: rgba(11, 76, 73, .68);
}

:global(.weight-nodes text) {
  font-size: 12px;
}

:global(.weight-axis-labels text) {
  font-size: 11px;
  fill: rgba(32, 91, 89, .46);
}

@keyframes draw-weight-line {
  to {
    stroke-dashoffset: 0;
  }
}

.weight-form {
  display: grid;
  grid-template-columns: 1fr 80px;
  gap: 10px;
  margin-top: 14px;
}

.weight-form.inline {
  grid-template-columns: minmax(160px, 1fr) 180px;
}

.total-pill {
  padding: 7px 10px;
  border-radius: 999px;
  color: #063c3a;
  font-size: 12px;
  font-weight: 900;
  background: #c8fff2;
}

.food-list {
  max-height: 420px;
  overflow: auto;
  padding-right: 4px;
  gap: 12px;
}

.food-row {
  display: grid;
  grid-template-columns: minmax(170px, 1fr) minmax(180px, auto) 34px;
  align-items: center;
  gap: 12px;
  padding: 14px;
  border: 1px solid rgba(55, 141, 136, .14);
  border-radius: 16px;
  background: rgba(255, 255, 255, .54);
}

.food-main strong,
.food-main span,
.food-main small {
  display: block;
}

.food-main span,
.food-main small {
  margin-top: 4px;
  font-size: 12px;
}

.food-metrics {
  display: grid;
  grid-template-columns: repeat(4, auto);
  align-items: center;
  gap: 7px;
}

.food-metrics em {
  color: #128b86;
  font-style: normal;
  font-weight: 900;
  white-space: nowrap;
}

.food-metrics span {
  padding: 6px 8px;
  border-radius: 999px;
  color: rgba(12, 88, 84, .78);
  font-size: 11px;
  font-weight: 900;
  background: rgba(207, 255, 243, .76);
}

.delete-action,
.icon-plain {
  display: grid;
  place-items: center;
  width: 32px;
  height: 32px;
  border: 1px solid rgba(55, 141, 136, .14);
  border-radius: 12px;
  color: #147b77;
  background: rgba(255, 255, 255, .52);
}

:global(.r6-shell.food-log .card-head) {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  margin-bottom: 18px;
}

:global(.r6-shell.food-log .food-list) {
  display: grid;
  gap: 12px;
  max-height: 420px;
  overflow: auto;
  padding-right: 4px;
}

:global(.r6-shell.food-log .food-row) {
  display: grid;
  grid-template-columns: minmax(180px, 1fr) minmax(220px, auto) 36px;
  align-items: center;
  gap: 14px;
  padding: 14px;
  border: 1px solid rgba(55, 141, 136, .14);
  border-radius: 18px;
  background: rgba(255, 255, 255, .58);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .74),
    0 12px 28px rgba(51, 174, 163, .08);
}

:global(.r6-shell.food-log .food-main strong),
:global(.r6-shell.food-log .food-main span),
:global(.r6-shell.food-log .food-main small) {
  display: block;
}

:global(.r6-shell.food-log .food-main strong) {
  color: #123c3b;
  font-size: 16px;
}

:global(.r6-shell.food-log .food-main span),
:global(.r6-shell.food-log .food-main small) {
  margin-top: 4px;
  color: rgba(32, 91, 89, .62);
  font-size: 12px;
}

:global(.r6-shell.food-log .food-metrics) {
  display: grid;
  grid-template-columns: auto repeat(3, auto);
  align-items: center;
  justify-content: end;
  gap: 7px;
}

:global(.r6-shell.food-log .food-metrics em) {
  color: #128b86;
  font-style: normal;
  font-weight: 900;
  white-space: nowrap;
}

:global(.r6-shell.food-log .food-metrics span) {
  display: inline-flex;
  align-items: center;
  min-height: 28px;
  padding: 0 9px;
  border-radius: 999px;
  color: rgba(12, 88, 84, .78);
  font-size: 11px;
  font-weight: 900;
  background: rgba(207, 255, 243, .78);
}

:global(.r6-shell.food-log .delete-action) {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  border: 1px solid rgba(55, 141, 136, .14);
  border-radius: 13px;
  color: #147b77;
  background: rgba(255, 255, 255, .62);
}

.preset-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.preset-grid button {
  min-height: 96px;
  padding: 16px;
  border: 1px solid rgba(55, 141, 136, .22);
  border-radius: 18px;
  color: #113b3a;
  text-align: left;
  background:
    linear-gradient(145deg, rgba(255, 255, 255, .78), rgba(235, 255, 251, .58)),
    rgba(255, 255, 255, .58);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .78),
    0 10px 24px rgba(42, 138, 132, .08);
}

.preset-grid strong,
.preset-grid span {
  display: block;
}

.preset-grid span {
  margin-top: 8px;
  color: rgba(32, 91, 89, .62);
  font-size: 13px;
}

.target-summary,
.week-grid {
  display: grid;
  gap: 12px;
}

.target-summary {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

.week-grid {
  grid-template-columns: repeat(7, minmax(0, 1fr));
}

.week-grid strong {
  margin: 14px 0 6px;
  font-size: 24px;
}

.account-actions {
  gap: 10px;
  margin-top: 18px;
  flex-wrap: wrap;
}

.modal-layer {
  position: fixed;
  inset: 0;
  z-index: 20;
  display: grid;
  place-items: center;
  padding: 32px;
  background: rgba(224, 248, 245, .68);
  backdrop-filter: blur(18px);
  -webkit-backdrop-filter: blur(18px);
}

.author-bubble {
  position: relative;
  z-index: 1;
  flex: 0 0 auto;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  min-width: 42px;
  min-height: 42px;
  padding: 0 14px;
  border: 1px solid rgba(66, 205, 195, .28);
  border-radius: 999px;
  color: #064b48;
  cursor: pointer;
  background:
    linear-gradient(150deg, rgba(244, 255, 253, .76), rgba(112, 232, 216, .34)),
    rgba(255, 255, 255, .44);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .9),
    0 12px 24px rgba(18, 112, 106, .12);
  opacity: .78;
  backdrop-filter: blur(14px) saturate(135%);
  -webkit-backdrop-filter: blur(14px) saturate(135%);
  transition: opacity .2s ease, border-color .2s ease, box-shadow .2s ease, translate .2s ease, transform .2s ease;
}

.author-bubble::after {
  content: "";
  position: absolute;
  inset: 4px;
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, .46);
  pointer-events: none;
}

.author-bubble:hover {
  translate: 0 -3px;
  opacity: 1;
  border-color: rgba(193, 255, 101, .72);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .94),
    0 16px 32px rgba(18, 112, 106, .18);
}

.author-bubble img {
  display: none;
}

.author-bubble svg {
  position: static;
  width: 16px;
  height: 16px;
  padding: 0;
  color: #074845;
  background: transparent;
  box-shadow: none;
}

.author-bubble span {
  position: static;
  width: auto;
  height: auto;
  overflow: visible;
  clip: auto;
  white-space: nowrap;
  color: rgba(7, 72, 69, .76);
  font-size: 11px;
  font-weight: 950;
}

.install-mini {
  display: none;
  align-items: center;
  justify-content: center;
  min-width: 42px;
  min-height: 42px;
  padding: 0;
  border: 1px solid rgba(66, 205, 195, .26);
  border-radius: 999px;
  color: #064b48;
  background:
    linear-gradient(150deg, rgba(244, 255, 253, .76), rgba(112, 232, 216, .34)),
    rgba(255, 255, 255, .44);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .9),
    0 12px 24px rgba(18, 112, 106, .12);
}

.author-layer {
  position: fixed;
  inset: 0;
  z-index: 26;
  display: grid;
  place-items: center;
  padding: 24px;
  background:
    radial-gradient(circle at 64% 48%, rgba(91, 232, 218, .22), transparent 28%),
    rgba(224, 248, 245, .42);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
}

.author-note {
  position: relative;
  width: min(430px, 100%);
  padding: 24px;
  border: 1px solid rgba(63, 196, 188, .32);
  border-radius: 34px;
  color: #083f3c;
  background:
    radial-gradient(circle at 20% 0%, rgba(255, 255, 255, .96), transparent 34%),
    radial-gradient(circle at 92% 82%, rgba(204, 255, 107, .38), transparent 34%),
    linear-gradient(150deg, rgba(255, 255, 255, .78), rgba(221, 255, 249, .7));
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .88),
    0 28px 70px rgba(17, 103, 98, .18);
  overflow: hidden;
}

.author-note::before {
  content: "";
  position: absolute;
  width: 170px;
  height: 170px;
  right: -74px;
  top: -58px;
  border-radius: 999px;
  background: conic-gradient(from 190deg, rgba(70, 224, 211, .18), rgba(207, 255, 100, .64), rgba(70, 224, 211, .18));
  opacity: .85;
  pointer-events: none;
}

.author-close {
  position: absolute;
  top: 18px;
  right: 18px;
  z-index: 2;
  width: 40px;
  height: 40px;
}

.author-note-head {
  position: relative;
  z-index: 1;
  display: grid;
  grid-template-columns: 82px minmax(0, 1fr);
  align-items: center;
  gap: 16px;
  padding-right: 44px;
}

.author-avatar {
  display: grid;
  place-items: center;
  width: 82px;
  height: 82px;
  border-radius: 28px;
  background:
    linear-gradient(145deg, rgba(255, 255, 255, .82), rgba(97, 228, 214, .32)),
    rgba(255, 255, 255, .62);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .9),
    0 16px 34px rgba(31, 142, 135, .18);
}

.author-avatar img {
  width: 70px;
  height: 70px;
  border-radius: 24px;
  object-fit: cover;
}

.author-note-head p {
  margin: 0 0 4px;
  color: rgba(9, 82, 78, .56);
  font-size: 12px;
  font-weight: 950;
  text-transform: uppercase;
}

.author-note-head h2 {
  margin: 0;
  color: #073f3c;
  font-size: 30px;
  line-height: 1.05;
  letter-spacing: 0;
}

.author-note-body {
  position: relative;
  z-index: 1;
  display: grid;
  gap: 12px;
  margin-top: 22px;
  padding: 18px;
  border: 1px solid rgba(74, 181, 174, .16);
  border-radius: 24px;
  background: rgba(255, 255, 255, .48);
}

.author-note-body p {
  margin: 0;
  color: rgba(9, 65, 62, .78);
  font-size: 15px;
  font-weight: 760;
  line-height: 1.75;
}

.author-note-foot {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-top: 16px;
  padding: 0 4px;
}

.author-note-foot span {
  color: rgba(9, 82, 78, .58);
  font-size: 12px;
  font-weight: 900;
}

.author-note-foot strong {
  color: #0b5d59;
  font-size: 15px;
}

.auth-card {
  width: min(760px, 100%);
}

.profile-modal {
  width: min(760px, 100%);
}

.modal-form {
  position: relative;
  display: grid;
  grid-template-columns: minmax(260px, .9fr) minmax(320px, 1.1fr);
  min-height: 430px;
}

.profile-form {
  display: grid;
  gap: 16px;
}

.auth-close {
  position: absolute;
  top: 22px;
  right: 22px;
  z-index: 2;
  width: 42px;
  height: 42px;
  border-radius: 999px;
}

.auth-showcase {
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 28px;
  min-height: 430px;
  padding: 38px 32px;
  color: #083f3c;
  background:
    radial-gradient(circle at 18% 14%, rgba(255, 255, 255, .82), transparent 24%),
    radial-gradient(circle at 82% 72%, rgba(178, 255, 223, .72), transparent 32%),
    linear-gradient(145deg, rgba(118, 231, 223, .36), rgba(235, 255, 249, .12));
}

.auth-showcase::after {
  content: "";
  position: absolute;
  inset: auto 26px 28px auto;
  width: 118px;
  aspect-ratio: 1;
  border-radius: 999px;
  background: conic-gradient(from 220deg, rgba(92, 229, 217, .16), rgba(191, 255, 119, .74), rgba(92, 229, 217, .16));
  opacity: .82;
}

.auth-mark {
  position: relative;
  z-index: 1;
  width: 82px;
  height: 82px;
  border-radius: 30px;
}

.auth-mark img {
  width: 84%;
  height: 84%;
}

.auth-showcase h2,
.auth-title h2 {
  margin: 0;
  line-height: 1.05;
}

.auth-showcase h2 {
  max-width: 300px;
  font-size: clamp(34px, 4vw, 48px);
  line-height: 1.16;
}

.auth-showcase p:not(.eyebrow) {
  position: relative;
  z-index: 1;
  max-width: 280px;
  margin: 14px 0 0;
  color: rgba(15, 81, 78, .68);
  line-height: 1.8;
}

.auth-flow-tags {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  max-width: 260px;
}

.auth-flow-tags span {
  display: inline-flex;
  align-items: center;
  min-height: 34px;
  border: 1px solid rgba(255, 255, 255, .62);
  border-radius: 999px;
  padding: 0 12px;
  color: rgba(11, 76, 73, .76);
  font-size: 12px;
  font-weight: 900;
  background: rgba(255, 255, 255, .32);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .66),
    0 10px 22px rgba(51, 174, 163, .08);
  backdrop-filter: blur(12px);
}

.auth-fields {
  display: grid;
  align-content: center;
  gap: 16px;
  padding: 52px 36px 36px;
}

.auth-title {
  margin-bottom: 8px;
  padding-right: 44px;
}

.auth-title h2 {
  font-size: 30px;
}

.auth-fields label {
  gap: 10px;
  padding: 15px 16px;
  border-radius: 24px;
  background: rgba(255, 255, 255, .54);
}

.auth-fields label input {
  min-height: 30px;
  font-size: 18px;
}

.auth-actions {
  display: flex;
  align-items: center;
  gap: 14px;
  flex-wrap: wrap;
  margin-top: 4px;
}

.auth-actions .primary-action {
  min-height: 50px;
  padding: 0 22px;
}

.form-message {
  margin: 0;
  color: #8a3030;
  font-weight: 700;
}

.text-action {
  border: 0;
  color: #167d79;
  background: transparent;
  font-weight: 900;
}

.profile-intro,
.empty-state {
  margin: 0 0 4px;
  line-height: 1.7;
}

.profile-control-panel {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.profile-toggle-block,
.range-field,
.activity-picker {
  border: 1px solid rgba(255, 255, 255, .66);
  border-radius: 26px;
  background:
    linear-gradient(145deg, rgba(255, 255, 255, .72), rgba(224, 255, 249, .42)),
    radial-gradient(circle at 12% 0%, rgba(126, 235, 221, .32), transparent 44%);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, .9),
    0 18px 42px rgba(61, 170, 160, .12);
  backdrop-filter: blur(16px);
}

.profile-toggle-block {
  display: grid;
  align-content: space-between;
  gap: 16px;
  min-height: 132px;
  padding: 18px;
}

.profile-toggle-block > span,
.range-head > span,
.activity-title span {
  color: rgba(20, 88, 84, .68);
  font-size: 13px;
  font-weight: 900;
}

.segmented-control {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 8px;
  padding: 6px;
  border-radius: 999px;
  background: rgba(255, 255, 255, .48);
}

.segmented-control button,
.activity-options button {
  border: 0;
  color: rgba(11, 65, 62, .68);
  font-weight: 900;
  background: transparent;
}

.segmented-control button {
  min-height: 42px;
  border-radius: 999px;
}

.segmented-control button.active,
.activity-options button.active {
  color: #063c3a;
  background: linear-gradient(135deg, #dfff75, #65e8dc);
  box-shadow: 0 14px 28px rgba(54, 185, 176, .18);
}

.range-field {
  gap: 16px;
  padding: 18px;
}

.range-head,
.range-scale,
.activity-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.range-head strong {
  display: inline-flex;
  align-items: baseline;
  gap: 6px;
  min-width: 118px;
  min-height: 48px;
  justify-content: center;
  padding: 0 14px;
  border: 1px solid rgba(255, 255, 255, .72);
  border-radius: 18px;
  color: #0b5f5b;
  background: rgba(255, 255, 255, .56);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, .78);
}

.range-head input {
  width: 62px;
  border: 0;
  outline: 0;
  color: inherit;
  font-size: 24px;
  font-weight: 900;
  text-align: right;
  background: transparent;
}

.range-head em {
  color: rgba(21, 91, 87, .62);
  font-size: 13px;
  font-style: normal;
  font-weight: 900;
}

.profile-range {
  width: 100%;
  height: 30px;
  margin: 2px 0;
  appearance: none;
  border-radius: 999px;
  background:
    linear-gradient(90deg, #dfff75 0 var(--fill), #61e6d9 var(--fill), rgba(255, 255, 255, .56) var(--fill)),
    rgba(255, 255, 255, .58);
  outline: none;
}

.profile-range::-webkit-slider-thumb {
  appearance: none;
  width: 32px;
  height: 32px;
  border: 6px solid rgba(255, 255, 255, .92);
  border-radius: 50%;
  background: linear-gradient(135deg, #0ccbbd, #e5ff75);
  box-shadow:
    0 12px 24px rgba(28, 159, 151, .28),
    inset 0 1px 0 rgba(255, 255, 255, .86);
  cursor: pointer;
}

.profile-range::-moz-range-thumb {
  width: 22px;
  height: 22px;
  border: 6px solid rgba(255, 255, 255, .92);
  border-radius: 50%;
  background: linear-gradient(135deg, #0ccbbd, #e5ff75);
  box-shadow: 0 12px 24px rgba(28, 159, 151, .28);
  cursor: pointer;
}

.range-scale {
  color: rgba(32, 91, 89, .54);
  font-size: 12px;
  font-weight: 800;
}

.range-scale small,
.activity-title small {
  color: rgba(32, 91, 89, .58);
  font-size: 12px;
}

.activity-picker {
  grid-column: 1 / -1;
  display: grid;
  gap: 12px;
  padding: 18px;
}

.activity-options {
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 8px;
}

.activity-options button {
  display: grid;
  gap: 4px;
  min-height: 64px;
  border-radius: 18px;
  background: rgba(255, 255, 255, .48);
}

.activity-options span {
  color: rgba(20, 88, 84, .52);
  font-size: 11px;
}

@keyframes drift {
  0%, 100% {
    transform: translate3d(0, 0, 0) rotate(0deg);
  }
  50% {
    transform: translate3d(18px, -24px, 0) rotate(8deg);
  }
}

@keyframes logoAura {
  0%, 100% {
    background-position: 0% 50%;
    transform: translateY(0);
  }
  50% {
    background-position: 100% 50%;
    transform: translateY(-1px);
  }
}

@keyframes logoSweep {
  0%, 36% {
    transform: translateX(-78%) rotate(8deg);
    opacity: 0;
  }
  50% {
    opacity: .95;
  }
  68%, 100% {
    transform: translateX(78%) rotate(8deg);
    opacity: 0;
  }
}

@keyframes railStatusFlow {
  to {
    transform: rotate(1turn);
  }
}

@keyframes railStatusPulse {
  0%, 100% {
    transform: scale(.84);
    opacity: .72;
  }
  50% {
    transform: scale(1.08);
    opacity: 1;
  }
}

@keyframes softReveal {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.result-list button,
.custom-item,
.food-row,
.card-head,
.meter-copy,
.ring-wrap,
.metric-row > div,
.hero-macros,
.hero-status-line,
.add-form > *,
.exercise-form > *,
.exercise-preview-grid > div,
.target-form > *,
.target-summary > div,
.calendar-summary-strip > div,
.calendar-weekday,
.calendar-day,
.account-summary > div,
.body-readout-item,
.weight-status-grid > div,
:global(.weight-chart),
:global(.r6-shell.food-log .food-row) {
  animation: softReveal .42s cubic-bezier(.2, .8, .2, 1) both;
}

.result-list button:nth-child(2),
.custom-item:nth-child(2),
.food-row:nth-child(2),
.metric-row > div:nth-child(2),
.add-form > *:nth-child(2),
.exercise-form > *:nth-child(2),
.exercise-preview-grid > div:nth-child(2),
.target-form > *:nth-child(2),
.target-summary > div:nth-child(2),
.calendar-summary-strip > div:nth-child(2),
.body-readout-item:nth-child(2),
.weight-status-grid > div:nth-child(2),
.calendar-day:nth-of-type(2),
:global(.r6-shell.food-log .food-row:nth-child(2)) {
  animation-delay: .05s;
}

.result-list button:nth-child(3),
.custom-item:nth-child(3),
.food-row:nth-child(3),
.metric-row > div:nth-child(3),
.add-form > *:nth-child(3),
.exercise-form > *:nth-child(3),
.exercise-preview-grid > div:nth-child(3),
.target-form > *:nth-child(3),
.target-summary > div:nth-child(3),
.calendar-summary-strip > div:nth-child(3),
.body-readout-item:nth-child(3),
.weight-status-grid > div:nth-child(3),
.calendar-day:nth-of-type(3),
:global(.r6-shell.food-log .food-row:nth-child(3)) {
  animation-delay: .1s;
}

.calendar-day:nth-of-type(4),
.result-list button:nth-child(4),
.custom-item:nth-child(4) {
  animation-delay: .14s;
}

.calendar-day:nth-of-type(5),
.result-list button:nth-child(5),
.custom-item:nth-child(5) {
  animation-delay: .18s;
}

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after,
  :global(*) {
    scroll-behavior: auto !important;
    animation-duration: .001ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: .001ms !important;
  }

  .modal-rise-enter-from :deep(.modal-form),
  .modal-rise-enter-from :deep(.profile-form),
  .modal-rise-leave-to :deep(.modal-form),
  .modal-rise-leave-to :deep(.profile-form) {
    transform: none !important;
  }
}

@media (max-width: 1180px) {
  .care-app {
    grid-template-columns: 1fr;
    gap: 16px;
    padding: 16px;
  }

  .side-rail,
  :global(.r6-shell.side-rail .r6-liquid > .glass) {
    height: auto;
    min-height: auto;
  }

  :global(.r6-shell.side-rail .r6-liquid),
  :global(.r6-shell.side-rail .r6-liquid > .glass > div:last-child) {
    height: auto;
  }

  :global(.r6-shell.side-rail .r6-liquid > .glass) {
    padding: 16px !important;
  }

  .side-rail {
    position: sticky;
    top: 10px;
    z-index: 8;
  }

  .brand {
    margin-bottom: 14px;
  }

  .side-rail nav {
    grid-template-columns: repeat(6, max-content);
    gap: 8px;
    overflow-x: auto;
    padding-bottom: 2px;
    align-items: start;
    scrollbar-width: none;
  }

  .side-rail nav::-webkit-scrollbar {
    display: none;
  }

  .side-rail nav button {
    min-width: 116px;
    min-height: 44px;
    justify-content: center;
    white-space: nowrap;
    border-radius: 999px;
  }

  .install-rail {
    display: grid;
  }

  .rail-status {
    display: none;
  }

  .dashboard-grid {
    grid-template-columns: 1fr;
    grid-auto-rows: auto;
  }

  .feature-grid {
    grid-template-columns: 1fr;
  }

  :global(.r6-shell.hero-meter .r6-liquid > .glass),
  .planner-card {
    min-height: auto;
  }

  .quick-add,
  .hero-meter {
    height: auto;
  }

  .topline h1 {
    font-size: clamp(34px, 6vw, 48px);
  }
}

@media (max-width: 920px) {
  .dashboard-grid,
  .feature-grid,
  .hero-meter,
  .profile-control-panel,
  .activity-options {
    grid-template-columns: 1fr;
  }

  :global(.r6-shell.hero-meter .r6-liquid > .glass > div:last-child) {
    grid-template-columns: 1fr;
    gap: 16px;
  }

  .topline {
    align-items: stretch;
    flex-direction: column;
  }

  .top-actions {
    justify-content: flex-start;
    flex-wrap: wrap;
  }

  .mega-number strong {
    font-size: clamp(56px, 13vw, 92px);
  }

  .ring-wrap {
    place-items: center;
  }

  .metric-row {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }

}

@media (max-width: 620px) {
  :global(html),
  :global(body),
  :global(#app) {
    width: 100%;
    max-width: 100%;
    overflow-x: hidden !important;
  }

  :global(*) {
    scrollbar-width: none;
  }

  :global(*::-webkit-scrollbar) {
    width: 0 !important;
    height: 0 !important;
  }

  .care-app {
    gap: 12px;
    width: 100%;
    max-width: 100dvw;
    padding: 10px 10px calc(108px + env(safe-area-inset-bottom));
    overflow-x: hidden;
    overflow-y: visible;
  }

  .author-bubble {
    min-width: 40px;
    min-height: 40px;
    padding: 0 12px;
    border-radius: 999px;
  }

  .author-bubble:hover {
    translate: 0 -3px;
  }

  .author-bubble img {
    display: none;
  }

  .author-bubble svg {
    width: 15px;
    height: 15px;
  }

  .author-layer {
    align-items: end;
    padding: 14px 12px calc(102px + env(safe-area-inset-bottom));
  }

  .author-note {
    padding: 20px;
    border-radius: 30px;
  }

  .author-note-head {
    grid-template-columns: 68px minmax(0, 1fr);
    gap: 12px;
    padding-right: 38px;
  }

  .author-avatar {
    width: 68px;
    height: 68px;
    border-radius: 24px;
  }

  .author-avatar img {
    width: 58px;
    height: 58px;
    border-radius: 20px;
  }

  .author-note-head h2 {
    font-size: 26px;
  }

  :global(.r6-shell.side-rail .r6-liquid > .glass),
  :global(.r6-shell.hero-meter .r6-liquid > .glass),
  :global(.r6-shell.quick-add .r6-liquid > .glass),
  :global(.r6-shell.food-log .r6-liquid > .glass),
  :global(.r6-shell.planner-card .r6-liquid > .glass),
  :global(.r6-shell.auth-card .r6-liquid > .glass) {
    padding: 14px !important;
    border-radius: 24px !important;
  }

  .brand {
    display: none;
  }

  .side-rail {
    position: fixed;
    left: 10px;
    right: auto;
    width: calc(100dvw - 20px);
    max-width: calc(100dvw - 20px);
    bottom: calc(8px + env(safe-area-inset-bottom));
    top: auto;
    z-index: 30;
    min-height: auto;
    contain: layout paint;
    overflow: hidden;
    border-radius: 24px;
    filter: drop-shadow(0 18px 28px rgba(12, 88, 84, .18));
  }

  :global(.r6-shell.side-rail .r6-liquid > .glass) {
    min-height: auto;
    padding: 8px !important;
    border-radius: 24px !important;
    border: 1px solid rgba(22, 153, 145, .38) !important;
    outline: 1px solid rgba(255, 255, 255, .86);
    outline-offset: -3px;
    background:
      linear-gradient(145deg, rgba(255, 255, 255, .9), rgba(224, 255, 250, .74)),
      rgba(238, 255, 252, .92) !important;
    backdrop-filter: blur(20px) saturate(150%) !important;
    -webkit-backdrop-filter: blur(20px) saturate(150%) !important;
    box-shadow:
      inset 0 1px 0 rgba(255, 255, 255, .96),
      inset 0 -1px 0 rgba(75, 205, 192, .28),
      0 0 0 1px rgba(109, 232, 219, .26),
      0 16px 36px rgba(18, 114, 109, .18) !important;
  }

  :global(.r6-shell.side-rail .r6-liquid),
  :global(.r6-shell.side-rail .r6-liquid > .glass) {
    overflow: hidden;
    max-width: 100%;
    background-color: transparent !important;
    isolation: isolate;
  }

  :global(.r6-shell.side-rail .glass__warp),
  :global(.r6-shell.side-rail canvas),
  :global(.r6-shell.side-rail .bg-black),
  :global(.r6-shell.side-rail .mix-blend-overlay) {
    display: none !important;
  }

  .side-rail nav {
    grid-template-columns: repeat(6, minmax(0, 1fr));
    gap: 4px;
    overflow: visible;
    padding-bottom: 0;
  }

  .side-rail nav button {
    min-width: 0;
    min-height: 50px;
    flex-direction: column;
    justify-content: center;
    gap: 4px;
    padding: 0 4px;
    border-radius: 16px;
    font-size: 11px;
    line-height: 1;
    color: rgba(18, 78, 75, .62);
    background: transparent;
    border: 1px solid transparent;
    box-shadow: none;
  }

  .side-rail nav button.active,
  .side-rail nav button:hover {
    color: #053c3a;
    background:
      linear-gradient(135deg, rgba(229, 255, 125, .64), rgba(106, 229, 219, .58)),
      rgba(255, 255, 255, .28);
    border-color: rgba(255, 255, 255, .62);
    box-shadow:
      inset 0 1px 0 rgba(255, 255, 255, .74),
      0 8px 18px rgba(49, 178, 169, .14);
  }

  .side-rail nav button svg {
    width: 17px;
    height: 17px;
  }

  .install-rail {
    display: none;
  }

  .install-mini {
    display: inline-flex;
  }

  .topline {
    gap: 12px;
    margin: 2px 0 14px;
  }

  .topline h1 {
    font-size: 34px;
    line-height: 1.08;
  }

  .top-actions {
    display: grid;
    grid-template-columns: 46px repeat(2, minmax(0, 1fr));
    gap: 8px;
  }

  .glass-button,
  .secondary-action,
  .primary-action,
  .danger-action {
    min-height: 42px;
    padding: 0 12px;
    font-size: 14px;
  }

  :global(.r6-shell.hero-meter .r6-liquid > .glass > div:last-child) {
    gap: 14px;
  }

  .mega-number {
    gap: 8px;
  }

  .mega-number strong {
    font-size: 64px;
  }

  .mega-number span {
    margin-bottom: 8px;
  }

  .hint {
    margin-top: 12px;
    font-size: 14px;
    line-height: 1.65;
  }

  .svg-ring {
    width: 150px;
  }

  .ring-core strong {
    font-size: 30px;
  }

  .metric-row {
    grid-template-columns: 1fr;
  }

  .metric-row div,
  .target-summary div,
  .week-grid div,
  .account-summary div,
  .body-readout-item {
    padding: 12px;
    border-radius: 16px;
  }

  .hero-macros {
    padding: 14px;
    border-radius: 20px;
  }

  .hero-macro-stack {
    grid-template-columns: 1fr;
    gap: 10px;
  }

  .selected-food {
    grid-template-columns: 1fr;
  }

  .selected-food > div:last-child {
    width: 100%;
  }

  .form-grid,
  .span-2,
  .split,
  .selected-food,
  .intake-preview,
  .food-row,
  .food-metrics,
  .target-summary,
  .week-grid,
  .preset-grid,
  .profile-control-panel,
  .activity-options,
  .custom-entry-form,
  .custom-actions,
  .weight-status-grid,
  .weight-form.inline {
    grid-template-columns: 1fr;
  }

  .body-readout {
    grid-template-columns: 1fr;
  }

  .profile-toggle-block {
    min-height: 108px;
    padding: 14px;
  }

  .activity-options {
    grid-template-columns: 1fr 1fr;
  }

  .range-head {
    align-items: flex-start;
    flex-direction: column;
  }

  .range-head strong {
    width: 100%;
    min-width: 0;
    justify-content: space-between;
  }

  .card-head {
    align-items: flex-start;
    gap: 10px;
  }

  .card-head h2 {
    font-size: 21px;
  }

  .selected-food {
    padding: 12px;
  }

  .grams-topline {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 8px;
  }

  .inline-kcal {
    font-size: 12px;
  }

  .inline-kcal strong {
    font-size: 28px;
  }

  .grams-field {
    min-height: auto;
  }

  .grams-control input {
    font-size: 28px;
  }

  .result-list {
    max-height: 232px;
    padding-right: 4px;
  }

  .weight-chart {
    min-height: 260px;
    padding: 16px 12px 10px;
  }

  .weight-chart svg {
    height: 218px;
  }

  .calendar-summary-strip {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 8px;
  }

  .calendar-summary-strip div {
    min-width: 0;
    padding: 10px 7px;
    border-radius: 16px;
  }

  .calendar-summary-strip span {
    font-size: 10px;
    white-space: nowrap;
  }

  .calendar-summary-strip strong {
    margin-top: 4px;
    font-size: clamp(15px, 4vw, 18px);
    line-height: 1.05;
    white-space: nowrap;
  }

  .calendar-grid {
    gap: 4px;
    width: 100%;
  }

  .calendar-weekday {
    padding: 0 0 2px;
    font-size: 10px;
    line-height: 1;
  }

  .calendar-day {
    min-width: 0;
    min-height: 66px;
    align-content: center;
    justify-items: center;
    gap: 4px;
    padding: 7px 3px;
    border-radius: 14px;
    text-align: center;
    overflow: hidden;
  }

  .calendar-day small,
  .calendar-day strong,
  .calendar-day span {
    max-width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .calendar-day small {
    font-size: 10px;
    line-height: 1;
  }

  .calendar-day strong {
    font-size: clamp(13px, 3.4vw, 16px);
    line-height: 1;
  }

  .calendar-day span {
    font-size: 10px;
    line-height: 1.05;
  }

  .span-2,
  .wide-feature {
    grid-column: auto;
  }

  .metric-row {
    flex-direction: column;
  }

  .modal-layer {
    place-items: stretch;
    padding: 12px 12px calc(18px + env(safe-area-inset-bottom));
    overflow: auto;
  }

  .auth-card,
  .profile-modal {
    width: 100%;
  }

  :global(.r6-shell.login-card .r6-liquid > .glass),
  :global(.r6-shell.profile-modal .r6-liquid > .glass) {
    width: 100% !important;
  }

  .modal-form {
    grid-template-columns: 1fr;
  }

  .auth-showcase {
    min-height: auto;
    padding: 26px 20px 22px;
  }

  .auth-fields {
    padding: 16px 20px 24px;
  }

  .auth-fields label {
    gap: 8px;
  }

  .auth-fields input {
    min-height: 46px;
    font-size: 15px;
  }

  .auth-actions {
    gap: 8px;
  }

  .auth-actions .primary-action,
  .auth-actions .text-action {
    min-height: 44px;
    padding: 0 14px;
    font-size: 14px;
  }

  .auth-actions .text-action {
    margin-bottom: 4px;
  }

  .auth-showcase h2,
  .auth-title h2 {
    font-size: 24px;
  }

  :global(.r6-shell.food-log .food-row),
  :global(.r6-shell.food-log .food-metrics) {
    grid-template-columns: 1fr;
    justify-content: stretch;
  }
}

@media (max-width: 430px) {
  .calendar-summary-strip {
    gap: 6px;
  }

  .calendar-summary-strip div {
    padding: 9px 5px;
  }

  .calendar-summary-strip strong {
    font-size: 14px;
  }

  .calendar-grid {
    gap: 3px;
  }

  .calendar-day {
    min-height: 60px;
    padding: 6px 2px;
    border-radius: 12px;
  }

  .calendar-day strong {
    font-size: 13px;
  }

  .calendar-day span {
    font-size: 9px;
  }
}
</style>


