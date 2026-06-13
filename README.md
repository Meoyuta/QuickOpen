# QuickOpen

[English](#english) | [中文](#中文)

## English

QuickOpen is a lightweight Spigot plugin that lets players quickly open useful items from their own inventory.

### Features

- Right-click a crafting table in your inventory to open a workbench.
- Right-click a shulker box in your inventory to open it directly.
- Works while another container GUI is open, but only for items in the player's own inventory area.
- Temporarily locks the opened shulker box slot with a placeholder item to prevent moving, swapping, dropping, or duplicating the source item while the virtual shulker inventory is open.
- Restores the shulker box on close, quit, death, or plugin disable.

### Requirements

- Java 17
- Spigot/Paper compatible with API version 1.21

### Installation

1. Download the latest jar from the GitHub Actions build artifacts or build it locally.
2. Put the jar into your server's `plugins` folder.
3. Restart the server.

### Build

```bash
mvn -DskipTests package
```

The compiled plugin jar will be generated under `target/`.

### Usage

Open your inventory, or any container GUI that also shows your inventory, then right-click a crafting table or shulker box in your own inventory.

QuickOpen intentionally does not open shulker boxes stored in the top container inventory. This avoids overwriting or conflicting with container changes made by other players, hoppers, or plugins.

### Notes

- This plugin does not require commands or permissions.
- The locked shulker placeholder is only used while a virtual shulker inventory is open.
- If you are testing on a live server, replace old plugin jars carefully and restart the server after updating.

## 中文

QuickOpen 是一个轻量级 Spigot 插件，用于让玩家从自己的背包中快速打开常用物品。

### 功能

- 在背包中右键工作台，直接打开工作台界面。
- 在背包中右键潜影盒，直接打开潜影盒内容。
- 在箱子等其它容器界面中也可使用，但只会响应玩家自己背包区域内的物品。
- 打开虚拟潜影盒时，会临时使用占位物锁定原潜影盒槽位，防止源物品被移动、交换、丢弃或复制。
- 在关闭界面、玩家退出、玩家死亡或插件禁用时恢复潜影盒。

### 环境要求

- Java 17
- 兼容 API version 1.21 的 Spigot/Paper 服务端

### 安装

1. 从 GitHub Actions 构建产物下载最新 jar，或在本地构建。
2. 将 jar 放入服务器的 `plugins` 文件夹。
3. 重启服务器。

### 构建

```bash
mvn -DskipTests package
```

构建后的插件 jar 会生成在 `target/` 目录下。

### 使用方式

打开玩家背包，或者打开任意会显示玩家背包区域的容器界面，然后右键自己背包中的工作台或潜影盒。

QuickOpen 有意不打开容器上半部分中的潜影盒。这样可以避免和其他玩家、漏斗或其它插件对容器内容的修改发生覆盖冲突。

### 说明

- 插件不需要命令或权限。
- 锁定占位物只会在虚拟潜影盒界面打开期间出现。
- 在真实服务器测试时，请谨慎替换旧 jar，并在更新后重启服务器。
