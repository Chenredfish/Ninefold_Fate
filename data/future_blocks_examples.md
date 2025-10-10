# 未來的多格凸塊設計範例

## 這個文件展示未來可能添加的多格凸塊類型

### L型凸塊
```json
{
  "B101": {
    "id": "B101",
    "name": {
      "zh": "L型火焰",
      "en": "L-Fire"
    },
    "element": "fire",
    "shape": "L_shape",
    "shape_pattern": [
      [1, 0],
      [1, 0], 
      [1, 1]
    ],
    "rotation_allowed": true,
    "flip_allowed": true,
    "bonus_value": 6,
    "rarity": "uncommon",
    "icon_path": "res://art/blocks/B101_icon.png"
  }
}
```

### 直線型凸塊
```json
{
  "B102": {
    "id": "B102",
    "name": {
      "zh": "直線水流",
      "en": "Line-Water"
    },
    "element": "water",
    "shape": "line_4",
    "shape_pattern": [[1, 1, 1, 1]],
    "rotation_allowed": true,
    "flip_allowed": false,
    "bonus_value": 8,
    "rarity": "uncommon",
    "icon_path": "res://art/blocks/B102_icon.png"
  }
}
```

### 十字型凸塊
```json
{
  "B201": {
    "id": "B201",
    "name": {
      "zh": "十字聖光",
      "en": "Cross-Light"
    },
    "element": "light",
    "shape": "cross",
    "shape_pattern": [
      [0, 1, 0],
      [1, 1, 1],
      [0, 1, 0]
    ],
    "rotation_allowed": false,
    "flip_allowed": false,
    "bonus_value": 10,
    "rarity": "rare",
    "icon_path": "res://art/blocks/B201_icon.png"
  }
}
```

### T型凸塊
```json
{
  "B103": {
    "id": "B103",
    "name": {
      "zh": "T型草葉",
      "en": "T-Grass"
    },
    "element": "grass",
    "shape": "T_shape",
    "shape_pattern": [
      [1, 1, 1],
      [0, 1, 0]
    ],
    "rotation_allowed": true,
    "flip_allowed": false,
    "bonus_value": 7,
    "rarity": "uncommon",
    "icon_path": "res://art/blocks/B103_icon.png"
  }
}
```

### 2x2方塊
```json
{
  "B104": {
    "id": "B104",
    "name": {
      "zh": "方形暗影",
      "en": "Square-Dark"
    },
    "element": "dark",
    "shape": "square",
    "shape_pattern": [
      [1, 1],
      [1, 1]
    ],
    "rotation_allowed": false,
    "flip_allowed": false,
    "bonus_value": 8,
    "rarity": "uncommon",
    "icon_path": "res://art/blocks/B104_icon.png"
  }
}
```

## 使用方法

當需要啟用多格凸塊時：
1. 將上述 JSON 複製到 `data/blocks.json`
2. ResourceManager 會自動處理形狀解析
3. 棋盤系統需要添加多格放置邏輯
4. UI 需要支援旋轉和翻轉操作