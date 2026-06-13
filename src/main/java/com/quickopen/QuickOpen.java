package com.quickopen;

import org.bukkit.Bukkit;
import org.bukkit.ChatColor;
import org.bukkit.Material;
import org.bukkit.NamespacedKey;
import org.bukkit.block.ShulkerBox;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.inventory.ClickType;
import org.bukkit.event.inventory.InventoryAction;
import org.bukkit.event.inventory.InventoryClickEvent;
import org.bukkit.event.inventory.InventoryCloseEvent;
import org.bukkit.event.inventory.InventoryDragEvent;
import org.bukkit.event.entity.PlayerDeathEvent;
import org.bukkit.event.player.PlayerQuitEvent;
import org.bukkit.inventory.Inventory;
import org.bukkit.inventory.InventoryView;
import org.bukkit.inventory.ItemStack;
import org.bukkit.inventory.meta.ItemMeta;
import org.bukkit.inventory.meta.BlockStateMeta;
import org.bukkit.persistence.PersistentDataType;
import org.bukkit.plugin.java.JavaPlugin;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

public class QuickOpen extends JavaPlugin implements Listener {

    private static final int OFFHAND_SLOT = 40;

    private final Map<UUID, ShulkerSession> openShulkers = new HashMap<>();
    private NamespacedKey lockedShulkerKey;

    @Override
    public void onEnable() {
        lockedShulkerKey = new NamespacedKey(this, "locked_shulker");
        getServer().getPluginManager().registerEvents(this, this);
        getLogger().info("QuickOpen enabled!");
    }

    @Override
    public void onDisable() {
        for (Map.Entry<UUID, ShulkerSession> entry : new HashMap<>(openShulkers).entrySet()) {
            Player player = Bukkit.getPlayer(entry.getKey());
            if (player != null) {
                restoreShulker(player, entry.getValue());
            }
        }
        openShulkers.clear();
    }

    @EventHandler
    public void onInventoryClick(InventoryClickEvent event) {
        if (!(event.getWhoClicked() instanceof Player player)) return;

        ShulkerSession session = openShulkers.get(player.getUniqueId());
        if (session != null && affectsLockedShulker(event, player, session)) {
            event.setCancelled(true);
            return;
        }

        // Must click inside the player's inventory, even when another container is open
        if (!player.getInventory().equals(event.getClickedInventory())) return;

        // Must be a right-click
        if (event.getClick() != ClickType.RIGHT) return;

        // Cursor must be empty
        ItemStack cursor = event.getView().getCursor();
        if (cursor != null && cursor.getType() != Material.AIR) return;

        // Must click on a valid item in the player's inventory
        ItemStack clicked = event.getCurrentItem();
        if (clicked == null || clicked.getType() == Material.AIR) return;

        Material type = clicked.getType();

        if (type == Material.CRAFTING_TABLE) {
            event.setCancelled(true);
            Bukkit.getScheduler().runTask(this, () -> {
                if (player.isOnline()) {
                    player.openWorkbench(null, true);
                }
            });
            return;
        }

        if (isShulkerBox(type)) {
            event.setCancelled(true);
            int slot = event.getSlot();
            Bukkit.getScheduler().runTask(this, () -> {
                if (!player.isOnline()) {
                    return;
                }

                ItemStack current = player.getInventory().getItem(slot);
                if (current != null && current.getType() != Material.AIR && isShulkerBox(current.getType())) {
                    openShulkerBox(player, current, slot);
                }
            });
        }
    }

    @EventHandler
    public void onInventoryDrag(InventoryDragEvent event) {
        if (!(event.getWhoClicked() instanceof Player player)) return;

        ShulkerSession session = openShulkers.get(player.getUniqueId());
        if (session == null) return;

        for (int rawSlot : event.getRawSlots()) {
            if (isPlayerInventorySlot(event.getView(), player, rawSlot, session.slot())) {
                event.setCancelled(true);
                return;
            }
        }
    }

    private boolean affectsLockedShulker(InventoryClickEvent event, Player player, ShulkerSession session) {
        if (player.getInventory().equals(event.getClickedInventory()) && event.getSlot() == session.slot()) {
            return true;
        }

        if (event.getClick() == ClickType.NUMBER_KEY && event.getHotbarButton() == session.slot()) {
            return true;
        }

        if (event.getClick() == ClickType.SWAP_OFFHAND && session.slot() == OFFHAND_SLOT) {
            return true;
        }

        if (event.getAction() == InventoryAction.HOTBAR_SWAP
                || event.getAction() == InventoryAction.HOTBAR_MOVE_AND_READD) {
            return event.getHotbarButton() == session.slot();
        }

        return isLockPlaceholder(event.getCurrentItem(), session) || isLockPlaceholder(event.getCursor(), session);
    }

    private boolean isPlayerInventorySlot(InventoryView view, Player player, int rawSlot, int slot) {
        return player.getInventory().equals(view.getInventory(rawSlot)) && view.convertSlot(rawSlot) == slot;
    }

    private boolean isShulkerBox(Material type) {
        return type == Material.SHULKER_BOX
                || type == Material.WHITE_SHULKER_BOX
                || type == Material.ORANGE_SHULKER_BOX
                || type == Material.MAGENTA_SHULKER_BOX
                || type == Material.LIGHT_BLUE_SHULKER_BOX
                || type == Material.YELLOW_SHULKER_BOX
                || type == Material.LIME_SHULKER_BOX
                || type == Material.PINK_SHULKER_BOX
                || type == Material.GRAY_SHULKER_BOX
                || type == Material.LIGHT_GRAY_SHULKER_BOX
                || type == Material.CYAN_SHULKER_BOX
                || type == Material.PURPLE_SHULKER_BOX
                || type == Material.BLUE_SHULKER_BOX
                || type == Material.BROWN_SHULKER_BOX
                || type == Material.GREEN_SHULKER_BOX
                || type == Material.RED_SHULKER_BOX
                || type == Material.BLACK_SHULKER_BOX;
    }

    private void openShulkerBox(Player player, ItemStack item, int slot) {
        if (!(item.getItemMeta() instanceof BlockStateMeta meta)) return;
        if (!(meta.getBlockState() instanceof ShulkerBox shulker)) return;

        ItemStack original = item.clone();
        String lockId = UUID.randomUUID().toString();
        Inventory shulkerInv = Bukkit.createInventory(null, 27, "Shulker Box");
        shulkerInv.setContents(shulker.getInventory().getContents());
        player.getInventory().setItem(slot, createLockPlaceholder(lockId));
        player.openInventory(shulkerInv);

        openShulkers.put(player.getUniqueId(), new ShulkerSession(slot, original, shulkerInv, lockId));
    }

    @EventHandler
    public void onInventoryClose(InventoryCloseEvent event) {
        if (!(event.getPlayer() instanceof Player player)) return;

        ShulkerSession session = openShulkers.get(player.getUniqueId());
        if (session == null) return;
        if (!event.getInventory().equals(session.inventory())) return;

        openShulkers.remove(player.getUniqueId());
        restoreShulker(player, session);
        flushCursor(player);
    }

    @EventHandler
    public void onPlayerQuit(PlayerQuitEvent event) {
        ShulkerSession session = openShulkers.remove(event.getPlayer().getUniqueId());
        if (session != null) {
            restoreShulker(event.getPlayer(), session);
        }
    }

    @EventHandler
    public void onPlayerDeath(PlayerDeathEvent event) {
        Player player = event.getEntity();
        ShulkerSession session = openShulkers.remove(player.getUniqueId());
        if (session == null) return;

        ItemStack restored = createUpdatedShulker(session);
        event.getDrops().removeIf(item -> isLockPlaceholder(item, session));
        if (event.getKeepInventory()) {
            replaceLockPlaceholder(player, session, restored);
        } else {
            event.getDrops().add(restored);
            player.getInventory().setItem(session.slot(), null);
        }
    }

    private ItemStack createLockPlaceholder(String lockId) {
        ItemStack placeholder = new ItemStack(Material.BARRIER);
        ItemMeta meta = placeholder.getItemMeta();
        if (meta != null) {
            meta.setDisplayName(ChatColor.RED + "Locked Shulker Box");
            meta.getPersistentDataContainer().set(lockedShulkerKey, PersistentDataType.STRING, lockId);
            placeholder.setItemMeta(meta);
        }
        return placeholder;
    }

    private boolean isLockPlaceholder(ItemStack item, ShulkerSession session) {
        if (item == null || item.getType() == Material.AIR || !item.hasItemMeta()) {
            return false;
        }

        ItemMeta meta = item.getItemMeta();
        if (meta == null) {
            return false;
        }

        String lockId = meta.getPersistentDataContainer().get(lockedShulkerKey, PersistentDataType.STRING);
        return session.lockId().equals(lockId);
    }

    private void restoreShulker(Player player, ShulkerSession session) {
        replaceLockPlaceholder(player, session, createUpdatedShulker(session));
    }

    private ItemStack createUpdatedShulker(ShulkerSession session) {
        ItemStack original = session.originalItem().clone();
        if (!(original.getItemMeta() instanceof BlockStateMeta meta)) return original;
        if (!(meta.getBlockState() instanceof ShulkerBox shulker)) return original;

        shulker.getInventory().setContents(session.inventory().getContents());
        meta.setBlockState(shulker);
        original.setItemMeta(meta);
        return original;
    }

    private void replaceLockPlaceholder(Player player, ShulkerSession session, ItemStack restored) {
        ItemStack sourceSlotItem = player.getInventory().getItem(session.slot());
        if (isLockPlaceholder(sourceSlotItem, session)) {
            player.getInventory().setItem(session.slot(), restored);
            return;
        }

        for (int slot = 0; slot < player.getInventory().getSize(); slot++) {
            ItemStack item = player.getInventory().getItem(slot);
            if (isLockPlaceholder(item, session)) {
                player.getInventory().setItem(slot, restored);
                return;
            }
        }

        Map<Integer, ItemStack> leftovers = player.getInventory().addItem(restored);
        for (ItemStack item : leftovers.values()) {
            player.getWorld().dropItemNaturally(player.getLocation(), item);
        }
    }

    private void flushCursor(Player player) {
        Bukkit.getScheduler().runTask(this, () -> {
            if (!player.isOnline()) {
                return;
            }

            ItemStack cursor = player.getItemOnCursor();
            if (cursor.getType() == Material.AIR) {
                player.setItemOnCursor(new ItemStack(Material.AIR));
            }
        });
    }

    private record ShulkerSession(int slot, ItemStack originalItem, Inventory inventory, String lockId) {
    }
}
