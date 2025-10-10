# 技能系統整合指南

## JSON 技能轉程式碼的完整解決方案

這個技能系統展示了如何將 JSON 中定義的技能轉換為實際的遊戲程式邏輯。

### 🏗️ 系統架構

```
JSON 技能數據 → SkillManager → 具體技能類 → 遊戲效果
    ↓              ↓              ↓            ↓
skills.json → 技能工廠模式 → FireMasterySkill → 傷害加成
heroes.json → 動態載入類別 → FireballSkill → 法術攻擊  
              Class 映射表 → HealSkill → 治療效果
```

### 📋 AutoLoad 設定

需要在 Godot 項目設置中添加以下 AutoLoad：

1. **SkillManager** - `res://singletons/SkillManager.gd`
   - 順序：在 ResourceManager 之後
   - 功能：技能數據庫和工廠模式管理

### 🎯 技能系統的三個層次

#### 1. 數據層 (JSON)
```json
{
  "S001": {
    "id": "S001",
    "type": "passive",
    "script_class": "FireMasterySkill",
    "parameters": {
      "damage_multiplier": 1.1
    }
  }
}
```

#### 2. 邏輯層 (GDScript 類)
```gdscript
class_name FireMasterySkill extends BaseSkill

func on_damage_dealt(damage_info: Dictionary) -> Dictionary:
    if damage_info.element == "fire":
        damage_info.amount *= parameters.damage_multiplier
    return damage_info
```

#### 3. 整合層 (SkillComponent)
```gdscript
# 英雄自動獲得技能組件
var skill_component = hero.get_node("SkillComponent")
skill_component.use_skill("S002", target)  # 使用火球術
```

### 🔄 工作流程

1. **創建英雄時**：
   ```gdscript
   var hero = ResourceManager.create_hero_with_skills("H001")
   # 自動從 heroes.json 讀取技能列表
   # 自動創建對應的技能實例
   # 自動附加 SkillComponent
   ```

2. **技能觸發時**：
   ```gdscript
   # 被動技能：自動觸發
   var modified_damage = skill_component.modify_outgoing_damage(damage_info)
   
   # 主動技能：手動調用
   skill_component.use_skill("S002", target)
   ```

3. **技能效果執行**：
   ```gdscript
   # 每個技能類實現具體的 execute() 方法
   # 處理冷卻、消耗、視覺效果等
   ```

### 🆕 新增技能的步驟

1. **定義 JSON 數據** (skills.json)
2. **創建技能類** (繼承 BaseSkill)
3. **註冊類別映射** (在 SkillManager 中)
4. **添加到英雄** (在 heroes.json 中)

### 💡 優勢特點

- ✅ **數據驅動**：技能參數完全由 JSON 控制
- ✅ **熱重載**：修改 JSON 後可動態重載
- ✅ **可擴展**：新增技能只需加類別和數據
- ✅ **模塊化**：技能邏輯與遊戲邏輯分離
- ✅ **類型安全**：編譯時檢查技能類別存在
- ✅ **事件整合**：與 EventBus 無縫配合

### 🧪 測試方法

運行 `SkillSystemTestScene.tscn` 來測試：
- 按 1：使用火球術攻擊敵人
- 按 2：使用治療術恢復血量  
- 按 3：測試被動技能傷害加成

### 🔮 未來擴展

這個系統可以輕鬆支持：
- 技能樹和前置條件
- 技能組合和連擊
- 狀態效果和 DoT 傷害
- 技能升級和變異
- AI 技能使用邏輯

---

**關鍵概念**：JSON 數據 + 工廠模式 + 組件系統 = 靈活的技能系統