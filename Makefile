# Makefile for kickstart.nvim configuration management
# Usage: make [target]

# Variables
NVIM_CONFIG_DIR := $(HOME)/.config/nvim
REPO_DIR := $(shell pwd)
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help install uninstall backup status update sync clean test

# Default target - show help
help:
	@echo "$(GREEN)Kickstart.nvim Configuration Manager$(NC)"
	@echo ""
	@echo "Available targets:"
	@echo "  $(YELLOW)make install$(NC)   - Create symlink from repo to Neovim config"
	@echo "  $(YELLOW)make uninstall$(NC) - Remove symlink and restore backup if exists"
	@echo "  $(YELLOW)make backup$(NC)    - Create backup of current config"
	@echo "  $(YELLOW)make status$(NC)    - Show current configuration status"
	@echo "  $(YELLOW)make update$(NC)    - Update plugins and Mason packages"
	@echo "  $(YELLOW)make sync$(NC)      - Pull latest changes and update plugins"
	@echo "  $(YELLOW)make clean$(NC)     - Clean plugin cache and reinstall"
	@echo "  $(YELLOW)make test$(NC)      - Test Neovim configuration"
	@echo ""
	@echo "Quick start: $(GREEN)make install$(NC)"

# Install configuration (create symlink)
install:
	@echo "$(GREEN)Installing Neovim configuration...$(NC)"
	@if [ -e "$(NVIM_CONFIG_DIR)" ] && [ ! -L "$(NVIM_CONFIG_DIR)" ]; then \
		echo "$(YELLOW)Backing up existing config...$(NC)"; \
		mv "$(NVIM_CONFIG_DIR)" "$(NVIM_CONFIG_DIR).backup.$(TIMESTAMP)"; \
	fi
	@if [ -L "$(NVIM_CONFIG_DIR)" ]; then \
		echo "$(YELLOW)Removing old symlink...$(NC)"; \
		rm "$(NVIM_CONFIG_DIR)"; \
	fi
	@echo "$(GREEN)Creating symlink...$(NC)"
	@ln -s "$(REPO_DIR)" "$(NVIM_CONFIG_DIR)"
	@echo "$(GREEN)✓ Configuration installed successfully!$(NC)"
	@echo ""
	@echo "Neo-tree shortcuts:"
	@echo "  $(YELLOW)\\$(NC)         - Reveal current file in tree"
	@echo "  $(YELLOW)<leader>e$(NC) - Toggle file explorer"
	@echo ""
	@echo "Run $(GREEN)nvim$(NC) to start with your new configuration!"

# Uninstall configuration
uninstall:
	@echo "$(RED)Uninstalling Neovim configuration...$(NC)"
	@if [ -L "$(NVIM_CONFIG_DIR)" ]; then \
		rm "$(NVIM_CONFIG_DIR)"; \
		echo "$(GREEN)✓ Symlink removed$(NC)"; \
	else \
		echo "$(YELLOW)No symlink found$(NC)"; \
	fi
	@LATEST_BACKUP=$$(ls -t $(NVIM_CONFIG_DIR).backup.* 2>/dev/null | head -n1); \
	if [ -n "$$LATEST_BACKUP" ]; then \
		echo "$(YELLOW)Latest backup found: $$LATEST_BACKUP$(NC)"; \
		echo "Run: mv $$LATEST_BACKUP $(NVIM_CONFIG_DIR) to restore"; \
	fi

# Create backup
backup:
	@echo "$(GREEN)Creating backup...$(NC)"
	@if [ -e "$(NVIM_CONFIG_DIR)" ]; then \
		cp -r "$(NVIM_CONFIG_DIR)" "$(NVIM_CONFIG_DIR).backup.$(TIMESTAMP)"; \
		echo "$(GREEN)✓ Backup created: $(NVIM_CONFIG_DIR).backup.$(TIMESTAMP)$(NC)"; \
	else \
		echo "$(RED)No configuration to backup$(NC)"; \
	fi

# Show status
status:
	@echo "$(GREEN)Configuration Status:$(NC)"
	@echo "Repository: $(REPO_DIR)"
	@if [ -L "$(NVIM_CONFIG_DIR)" ]; then \
		echo "Config: $(GREEN)✓ Linked$(NC) -> $$(readlink $(NVIM_CONFIG_DIR))"; \
	elif [ -d "$(NVIM_CONFIG_DIR)" ]; then \
		echo "Config: $(YELLOW)⚠ Directory exists but not linked$(NC)"; \
	else \
		echo "Config: $(RED)✗ Not configured$(NC)"; \
	fi
	@echo ""
	@if [ -L "$(NVIM_CONFIG_DIR)" ]; then \
		cd "$(REPO_DIR)" && echo "Git status:" && git status --short; \
	fi

# Update plugins
update:
	@echo "$(GREEN)Updating Neovim plugins...$(NC)"
	@nvim --headless "+Lazy sync" +qa
	@echo "$(GREEN)Updating Mason packages...$(NC)"
	@nvim --headless "+MasonUpdate" +qa
	@echo "$(GREEN)✓ Updates complete!$(NC)"

# Sync with git and update
sync:
	@echo "$(GREEN)Syncing with git repository...$(NC)"
	@cd "$(REPO_DIR)" && git pull
	@$(MAKE) update

# Clean and reinstall plugins
clean:
	@echo "$(RED)Cleaning plugin cache...$(NC)"
	@rm -rf $(HOME)/.local/share/nvim/lazy
	@rm -rf $(HOME)/.local/share/nvim/mason
	@echo "$(GREEN)Reinstalling plugins...$(NC)"
	@nvim --headless "+Lazy sync" +qa
	@echo "$(GREEN)✓ Clean installation complete!$(NC)"

# Test configuration
test:
	@echo "$(GREEN)Testing Neovim configuration...$(NC)"
	@nvim --headless -c "echo 'Config OK'" -c "qa" 2>&1 | grep -q "Config OK" && \
		echo "$(GREEN)✓ Configuration loads successfully$(NC)" || \
		echo "$(RED)✗ Configuration has errors$(NC)"
	@echo ""
	@echo "Checking for Neo-tree..."
	@nvim --headless -c "lua print(pcall(require, 'neo-tree') and 'Neo-tree OK' or 'Neo-tree missing')" -c "qa" 2>&1 | \
		grep -q "Neo-tree OK" && echo "$(GREEN)✓ Neo-tree is installed$(NC)" || echo "$(YELLOW)⚠ Neo-tree not found$(NC)"