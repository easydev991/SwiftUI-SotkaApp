.PHONY: help setup setup_hook setup_fastlane update update_bundle update_swiftformat format screenshots

# Цвета и шрифт
YELLOW=\033[1;33m
GREEN=\033[1;32m
RED=\033[1;31m
BOLD=\033[1m
RESET=\033[0m

# Версия Ruby в проекте
RUBY_VERSION=3.2.2

# Версия Swift в проекте
SWIFT_VERSION=6.0

help:
	@echo ""
	@echo "Доступные команды Makefile:"
	@echo ""
	@printf "$(BOLD)make help$(RESET)                - Показать это справочное сообщение\n"
	@printf "$(BOLD)make setup$(RESET)               - Проверить и установить все необходимые инструменты и зависимости для проекта:\n"
	@echo   "Homebrew, rbenv, Ruby, Bundler, Ruby-гемы, fastlane snapshot, swiftformat"
	@printf "$(BOLD)make setup_hook$(RESET)          - Установить pre-push git-хук для проверки форматирования Swift-кода\n"
	@printf "$(BOLD)make setup_fastlane$(RESET)      - Проверить инициализацию fastlane/fastlane snapshot, при необходимости предложить варианты установки\n"
	@printf "$(BOLD)make update$(RESET)              - Обновить fastlane и swiftformat (вызывает update_bundle и update_swiftformat)\n"
	@printf "$(BOLD)make update_bundle$(RESET)       - Обновить только fastlane и его зависимости.\n"
	@printf "$(BOLD)make update_swiftformat$(RESET)  - Обновить только swiftformat через Homebrew\n"
	@printf "$(BOLD)make format$(RESET)              - Запустить автоматическое форматирование Swift-кода с помощью swiftformat\n"
	@printf "$(BOLD)make screenshots$(RESET)         - Запустить fastlane snapshot для генерации скриншотов приложения\n"
	@echo ""
	@echo "Рекомендуется сначала выполнить команду '$(BOLD)make setup$(RESET)'"
	@echo ""

setup:
	@printf "$(YELLOW)Проверка наличия Homebrew...$(RESET)\n"
	@if ! command -v brew >/dev/null 2>&1; then \
		printf "$(YELLOW)Homebrew не установлен$(RESET)\n"; \
		read -p "Установить Homebrew? (да/нет) " answer; \
		if echo "$${answer}" | grep -iq "^да$$"; then \
			/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
			printf "$(GREEN)Homebrew успешно установлен$(RESET)\n"; \
		else \
			printf "$(RED)Невозможно продолжить без Homebrew$(RESET)\n"; \
			exit 1; \
		fi \
	else \
		printf "$(GREEN)Homebrew уже установлен$(RESET)\n"; \
	fi

	@printf "$(YELLOW)Проверка наличия rbenv...$(RESET)\n"
	@if ! command -v rbenv >/dev/null 2>&1; then \
		printf "$(YELLOW)rbenv не установлен$(RESET)\n"; \
		read -p "Установить rbenv? (да/нет) " answer; \
		if echo "$${answer}" | grep -iq "^да$$"; then \
			brew install rbenv ruby-build; \
			printf 'eval "$$(rbenv init -)"\n' >> ~/.bash_profile; \
			printf "$(GREEN)rbenv успешно установлен$(RESET)\n"; \
		else \
			printf "$(RED)Невозможно продолжить без rbenv$(RESET)\n"; \
			exit 1; \
		fi \
	else \
		printf "$(GREEN)rbenv уже установлен$(RESET)\n"; \
	fi

	@printf "$(YELLOW)Проверка наличия Ruby версии $(RUBY_VERSION)...$(RESET)\n"
	@if ! rbenv versions | grep -q $(RUBY_VERSION); then \
		printf "$(YELLOW)Ruby $(RUBY_VERSION) не установлен$(RESET)\n"; \
		read -p "Установить Ruby $(RUBY_VERSION)? (да/нет) " answer; \
		if echo "$${answer}" | grep -iq "^да$$"; then \
			rbenv install $(RUBY_VERSION); \
			printf "$(GREEN)Ruby $(RUBY_VERSION) успешно установлен$(RESET)\n"; \
		else \
			printf "$(RED)Невозможно продолжить без Ruby $(RUBY_VERSION)$(RESET)\n"; \
			exit 1; \
		fi \
	else \
		printf "$(GREEN)Ruby $(RUBY_VERSION) уже установлен$(RESET)\n"; \
	fi

	@printf "$(YELLOW)Проверка файла .ruby-version...$(RESET)\n"
	@if [ ! -f .ruby-version ] || [ "$$(cat .ruby-version)" != "$(RUBY_VERSION)" ]; then \
		printf "$(YELLOW)Файл .ruby-version не найден или содержит неверную версию$(RESET)\n"; \
		read -p "Создать/обновить файл .ruby-version с версией $(RUBY_VERSION)? (да/нет) " answer; \
		if echo "$${answer}" | grep -iq "^да$$"; then \
			echo "$(RUBY_VERSION)" > .ruby-version; \
			printf "$(GREEN)Файл .ruby-version обновлён$(RESET)\n"; \
		else \
			printf "$(YELLOW)Создание файла .ruby-version пропущено$(RESET)\n"; \
		fi \
	else \
		printf "$(GREEN)Файл .ruby-version уже корректно настроен$(RESET)\n"; \
	fi

	@printf "$(YELLOW)Инициализация rbenv и активация Ruby $(RUBY_VERSION) локально...$(RESET)\n"
	@export PATH="$$HOME/.rbenv/bin:$$PATH"; \
	eval "$$(rbenv init -)"; \
	rbenv local $(RUBY_VERSION); \
	rbenv shell $(RUBY_VERSION); \
	printf "$(GREEN)Ruby $(RUBY_VERSION) активирован локально для проекта$(RESET)\n"

	@printf "$(YELLOW)Проверка наличия Bundler нужной версии...$(RESET)\n"
	@if [ -f Gemfile.lock ]; then \
		BUNDLER_VERSION=$$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1 | xargs); \
		if ! gem list -i bundler -v "$$BUNDLER_VERSION" >/dev/null 2>&1; then \
			printf "$(YELLOW)Bundler версии $$BUNDLER_VERSION не установлен$(RESET)\n"; \
			read -p "Установить Bundler $$BUNDLER_VERSION? (да/нет) " answer; \
			if echo "$${answer}" | grep -iq "^да$$"; then \
				gem install bundler -v "$$BUNDLER_VERSION"; \
				printf "$(GREEN)Bundler версии $$BUNDLER_VERSION успешно установлен$(RESET)\n"; \
			else \
				printf "$(RED)Невозможно продолжить без Bundler $$BUNDLER_VERSION$(RESET)\n"; \
				exit 1; \
			fi \
		else \
			printf "$(GREEN)Bundler версии $$BUNDLER_VERSION уже установлен$(RESET)\n"; \
		fi \
	else \
		printf "$(YELLOW)Файл Gemfile.lock не найден, пропуск проверки версии Bundler$(RESET)\n"; \
	fi
	
	@printf "$(YELLOW)Проверка наличия Gemfile...$(RESET)\n"
	@if [ ! -f Gemfile ]; then \
		printf "$(YELLOW)Gemfile не найден. Создаю новый Gemfile...$(RESET)\n"; \
		bundle init; \
		printf "gem 'fastlane'\n" >> Gemfile; \
		printf "$(GREEN)Gemfile создан и fastlane добавлен в зависимости$(RESET)\n"; \
	else \
		printf "$(GREEN)Gemfile уже существует$(RESET)\n"; \
	fi

	@printf "$(YELLOW)Проверка Ruby-зависимостей из Gemfile...$(RESET)\n"
	@if [ -f Gemfile ]; then \
		if ! bundle check >/dev/null 2>&1; then \
			printf "$(YELLOW)Зависимости не установлены. Выполняется bundle install...$(RESET)\n"; \
			bundle install; \
			if [ $$? -ne 0 ]; then \
				printf "$(RED)Невозможно продолжить без всех Ruby-зависимостей$(RESET)\n"; \
				exit 1; \
			fi; \
			printf "$(GREEN)Все Ruby-зависимости успешно установлены$(RESET)\n"; \
		else \
			printf "$(GREEN)Все Ruby-зависимости уже установлены$(RESET)\n"; \
		fi \
	else \
		printf "$(YELLOW)Файл Gemfile не найден, пропуск установки Ruby-зависимостей$(RESET)\n"; \
	fi

	@printf "$(YELLOW)Проверка наличия swiftformat...$(RESET)\n"
	@if ! command -v swiftformat >/dev/null 2>&1; then \
		printf "$(YELLOW)swiftformat не установлен$(RESET)\n"; \
		read -p "Установить swiftformat? (да/нет) " answer; \
		if echo "$${answer}" | grep -iq "^да$$"; then \
			brew install swiftformat; \
			printf "$(GREEN)swiftformat успешно установлен$(RESET)\n"; \
		else \
			printf "$(RED)Невозможно продолжить без swiftformat$(RESET)\n"; \
			exit 1; \
		fi \
	else \
		printf "$(GREEN)swiftformat уже установлен$(RESET)\n"; \
	fi
	
	@$(MAKE) setup_hook
	
	@$(MAKE) setup_fastlane
	
setup_hook:
	@HOOK_PATH=".git/hooks/pre-push"; \
	if [ -f "$$HOOK_PATH" ] && grep -q "swiftformat" "$$HOOK_PATH"; then \
		printf "$(GREEN)pre-push git-хук для проверки форматирования кода уже настроен$(RESET)\n"; \
	else \
		printf "$(YELLOW)Устанавливаю pre-push git-хук для swiftformat...$(RESET)\n"; \
		echo '#!/usr/bin/env bash' > "$$HOOK_PATH"; \
		echo 'export PATH="/opt/homebrew/bin:/usr/local/bin:$$PATH"' >> "$$HOOK_PATH"; \
		echo '' >> "$$HOOK_PATH"; \
		echo 'if ! swiftformat . --lint; then' >> "$$HOOK_PATH"; \
		echo '  echo ""' >> "$$HOOK_PATH"; \
		echo '  echo "Похоже, есть код, который нужно отформатировать."' >> "$$HOOK_PATH"; \
		echo '  echo "Запусти команду: make format"' >> "$$HOOK_PATH"; \
		echo '  echo ""' >> "$$HOOK_PATH"; \
		echo '  exit 1' >> "$$HOOK_PATH"; \
		echo 'else' >> "$$HOOK_PATH"; \
		echo '  exit 0' >> "$$HOOK_PATH"; \
		echo 'fi' >> "$$HOOK_PATH"; \
		chmod +x "$$HOOK_PATH"; \
		printf "$(GREEN)pre-push git-хук для swiftformat успешно установлен в .git/hooks$(RESET)\n"; \
	fi

setup_fastlane:
	@printf "$(YELLOW)Проверка установки fastlane...$(RESET)\n"
	@if [ -d fastlane ] && [ -f fastlane/Fastfile ]; then \
		printf "$(GREEN)fastlane уже инициализирован в проекте$(RESET)\n"; \
		if [ ! -f fastlane/Snapfile ]; then \
			printf "$(YELLOW)Snapfile не найден, выполняется инициализация fastlane snapshot...$(RESET)\n"; \
			bundle exec fastlane snapshot init; \
			printf "$(GREEN)fastlane snapshot успешно инициализирован$(RESET)\n"; \
		else \
			printf "$(GREEN)fastlane snapshot уже готов к использованию$(RESET)\n"; \
		fi \
	else \
		printf "$(YELLOW)fastlane не инициализирован в проекте$(RESET)\n"; \
		printf "Выберите действие:\n"; \
		printf "  1 — Установить только fastlane snapshot (Snapfile, без Fastfile)\n"; \
		printf "  2 — Не устанавливать fastlane (вы сможете сделать это вручную)\n"; \
		read -p "Ваш выбор (1/2): " choice; \
		if [ "$$choice" = "1" ]; then \
			if [ ! -f fastlane/Snapfile ]; then \
				mkdir -p fastlane; \
				bundle exec fastlane snapshot init; \
				printf "$(GREEN)fastlane snapshot успешно инициализирован$(RESET)\n"; \
			else \
				printf "$(GREEN)fastlane snapshot уже готов к использованию$(RESET)\n"; \
			fi \
		else \
			printf "$(YELLOW)Вы можете установить fastlane вручную командой:$(RESET)\n"; \
			printf "  bundle exec fastlane init\n"; \
			printf "$(YELLOW)После этого можно запустить генерацию скриншотов командой 'make screenshots'$(RESET)\n"; \
		fi \
	fi

update: update_bundle update_swiftformat

update_bundle:
	@printf "$(YELLOW)Проверка наличия обновлений fastlane и его зависимостей...$(RESET)\n"
	@if bundle outdated fastlane --parseable | grep .; then \
		printf "$(YELLOW)Есть обновления для fastlane или его зависимостей, выполняется обновление...$(RESET)\n"; \
		bundle update fastlane; \
		printf "$(GREEN)fastlane и его зависимости обновлены. Не забудьте закоммитить новый Gemfile.lock!$(RESET)\n"; \
	else \
		printf "$(GREEN)fastlane и его зависимости уже самые свежие$(RESET)\n"; \
	fi

update_swiftformat:
	@printf "$(YELLOW)Проверка наличия обновлений swiftformat...$(RESET)\n"
	@INSTALLED_VER=$$(brew list --versions swiftformat | awk '{print $$2}'); \
	LATEST_VER=$$(brew info swiftformat --json=v1 | grep -m 1 '"versions"' -A 4 | grep '"stable"' | awk -F'"' '{print $$4}'); \
	if [ "$$INSTALLED_VER" != "$$LATEST_VER" ]; then \
		printf "$(YELLOW)Доступна новая версия swiftformat ($$INSTALLED_VER -> $$LATEST_VER), обновление...$(RESET)\n"; \
		brew upgrade swiftformat; \
		printf "$(GREEN)swiftformat обновлён до версии $$LATEST_VER$(RESET)\n"; \
	else \
		printf "$(GREEN)swiftformat уже самой свежей версии ($$INSTALLED_VER)$(RESET)\n"; \
	fi

format:
	@if ! command -v brew >/dev/null 2>&1 || ! command -v swiftformat >/dev/null 2>&1; then \
		$(MAKE) setup; \
	fi; \
	if ! command -v brew >/dev/null 2>&1 || ! command -v swiftformat >/dev/null 2>&1; then \
		printf "$(RED)Невозможно выполнить команду без нужных зависимостей$(RESET)\n"; \
		exit 1; \
	fi
	@if [ ! -f .swift-version ]; then \
		printf "$(YELLOW)Файл .swift-version не найден. Создаю файл с версией Swift $(SWIFT_VERSION)...$(RESET)\n"; \
		echo "$(SWIFT_VERSION)" > .swift-version; \
		printf "$(GREEN)Файл .swift-version создан с версией $(SWIFT_VERSION)$(RESET)\n"; \
	else \
		printf "$(GREEN)Файл .swift-version уже существует$(RESET)\n"; \
	fi
	@printf "$(YELLOW)Запуск swiftformat...$(RESET)\n"
	@swiftformat .

screenshots:
	@if [ ! -d fastlane ] || [ ! -f fastlane/Fastfile ]; then \
		printf "$(YELLOW)fastlane не инициализирован в проекте$(RESET)\n"; \
		$(MAKE) setup_fastlane; \
		if [ ! -d fastlane ] || [ ! -f fastlane/Fastfile ]; then \
			printf "$(RED)Нужно инициализировать fastlane перед использованием$(RESET)\n"; \
			exit 1; \
		fi \
	fi
	@printf "$(YELLOW)Запуск fastlane snapshot...$(RESET)\n"
	@bundle exec fastlane snapshot

.DEFAULT:
	@printf "$(RED)Неизвестная команда: 'make $@'\n$(RESET)"
	@$(MAKE) help
