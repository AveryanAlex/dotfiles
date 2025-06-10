{
  inputs,
  pkgs,
  lib,
  ...
}: {
  age.secrets.account-wakatime = {
    file = ../secrets/accounts/wakatime.age;
    owner = "alex";
    group = "users";
    path = "/home/alex/.wakatime.cfg";
  };

  hm = {
    home.packages = with pkgs; [gh-copilot];

    home.sessionVariables.NIXOS_OZONE_WL = "1";

    home.file.".vscode/argv.json".text = builtins.toJSON {
      enable-crash-reporter = false;
      password-store = "gnome";
    };

    programs.vscode = {
      enable = true;
      package = pkgs.vscode;

      mutableExtensionsDir = false;
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;

      extensions = let
        vm = inputs.nix-vscode-extensions.extensions.${pkgs.hostPlatform.system}.vscode-marketplace;
      in [
        # Python
        vm.ms-python.black-formatter
        vm.ms-python.debugpy
        vm.ms-python.isort
        vm.ms-python.mypy-type-checker
        vm.ms-python.python
        (vm.ms-python.vscode-pylance.override {meta.license = [];})
        vm.njpwerner.autodocstring

        # Jupyter
        pkgs.vscode-extensions.ms-toolsai.jupyter
        pkgs.vscode-extensions.ms-toolsai.jupyter-renderers
        vm.ms-toolsai.datawrangler

        # Other langs
        pkgs.vscode-extensions.jnoortheen.nix-ide
        pkgs.vscode-extensions.rust-lang.rust-analyzer
        vm.galarius.vscode-opencl
        vm.github.vscode-github-actions
        vm.james-yu.latex-workshop
        vm.mechatroner.rainbow-csv
        # vm.ms-vscode.cpptools
        # pkgs.vscode-extensions.ms-vscode.cpptools
        pkgs.vscode-extensions.llvm-vs-code-extensions.vscode-clangd
        pkgs.vscode-extensions.vadimcn.vscode-lldb
        pkgs.vscode-extensions.ms-vscode.cmake-tools
        pkgs.vscode-extensions.twxs.cmake
        vm.redhat.java
        vm.redhat.vscode-xml
        vm.redhat.vscode-yaml
        vm.tamasfe.even-better-toml
        # vscode-marketplace.ms-azuretools.vscode-docker
        pkgs.vscode-extensions.myriad-dreamin.tinymist
        vm.orangex4.vscode-typst-sympy-calculator

        vm.davidanson.vscode-markdownlint
        vm.yzhang.markdown-all-in-one

        # SQL
        vm.loyieking.smalise
        vm.mtxr.sqltools
        vm.mtxr.sqltools-driver-mysql
        vm.mtxr.sqltools-driver-pg
        vm.mtxr.sqltools-driver-sqlite
        vm.surendrajat.apklab

        # Tools
        # pkgs.vscode-extensions.github.copilot-chat
        vm.bierner.emojisense
        # vm.bito.bito
        vm.earshinov.sort-lines-by-selection
        vm.editorconfig.editorconfig
        (vm.fill-labs.dependi.override {meta.license = [];})
        # vm.github.copilot
        vm.github.vscode-pull-request-github
        vm.gruntfuggly.todo-tree
        vm.stkb.rewrap
        vm.tyriar.sort-lines
        (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
          mktplcRef = let
            sources = {
              "x86_64-linux" = {
                arch = "linux-x64";
                hash = "sha256-EjaYwZlO9mOlTyUEOXxcxRU/KQj5xt0s8EscBD+Dv8k=";
              };
            };
          in
            {
              name = "continue";
              publisher = "Continue";
              version = "1.1.35";
            }
            // sources.${pkgs.stdenv.system};
          nativeBuildInputs = [pkgs.autoPatchelfHook];
          buildInputs = [(lib.getLib pkgs.stdenv.cc.cc)];
          meta = {
            platforms = [
              "x86_64-linux"
            ];
          };
        })
        # vm.saoudrizwan.claude-dev
        vm.rooveterinaryinc.roo-cline

        # JavaScript
        vm.svelte.svelte-vscode

        # Misc
        vm.donjayamanne.githistory
        # vm.gitlab.gitlab-workflow
        vm.mkhl.direnv
        vm.wakatime.vscode-wakatime
      ];
      userSettings = {
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = lib.getExe pkgs.nixd;
        "nix.serverSettings" = {
          nixd = {
            formatting = {
              command = ["${pkgs.alejandra}/bin/alejandra"];
            };
            options = {
              nixos = {
                expr = "(builtins.getFlake \"/home/alex/projects/averyanalex/nixcfg\").nixosConfigurations.alligator.options";
              };
            };
          };
        };

        "rust-analyzer.check.command" = "clippy";

        "editor.quickSuggestions" = {
          "strings" = true;
        };
        "editor.tabCompletion" = "on";
        "editor.formatOnSave" = true;

        # VCS
        "diffEditor.ignoreTrimWhitespace" = false;
        "git.autofetch" = true;
        "git.confirmSync" = false;
        "git.enableSmartCommit" = true;

        "editor.fontLigatures" = "'calt', 'ss01', 'ss02', 'ss03', 'ss04', 'ss05', 'ss06', 'ss07', 'ss08', 'ss09', 'liga'";
        "editor.fontFamily" = "'Monaspace Neon', monospace";
        "terminal.integrated.fontFamily" = "MesloLGS NF";

        # Other
        "editor.unicodeHighlight.allowedLocales".ru = true;
        "files.autoSave" = "afterDelay";
        "redhat.telemetry.enabled" = false;
        "sortLines.filterBlankLines" = true;
        "workbench.startupEditor" = "none";
        "direnv.restart.automatic" = true;
        "extensions.ignoreRecommendations" = true;

        "C_Cpp.clang_format_path" = "${pkgs.clang-tools}/bin/clang-format";
        "OpenCL.formatting.name" = "${pkgs.clang-tools}/bin/clang-format";

        # "cmake.debugConfig" = {
        #   "MIMode" = "lldb";
        # };

        # Python
        "python.analysis.autoImportCompletions" = true;
        "black-formatter.path" = ["black"];
        # "python.formatting.provider" = "black";
        "python.languageServer" = "Pylance";
        "python.analysis.typeCheckingMode" = "standard";
        "mypy-type-checker.args" = ["--disable-error-code=import-untyped"];
        "mypy-type-checker.severity" = {
          "error" = "Warning";
          "note" = "Information";
        };
        # "mypy-type-checker.path" = [ "${pkgs.mypy}/bin/mypy" ];
        "python.poetryPath" = "${pkgs.poetry}/bin/poetry";
        "python.venvPath" = "~/.cache/pypoetry/virtualenvs";
        "isort.path" = ["isort"]; # ${pkgs.python3Packages.isort}/bin/
        "python.testing.pytestEnabled" = true;
        "python.testing.pytestPath" = "${pkgs.python3Packages.pytest}/bin/pytest";
        "python.defaultInterpreterPath" = "${lib.getExe ((import ./python.nix) pkgs)}";
        "python.terminal.activateEnvironment" = false;

        "C_Cpp.default.cppStandard" = "c++23";
        "C_Cpp.default.cStandard" = "c23";

        "svelte.enable-ts-plugin" = true;

        "roo-cline.allowedCommands" = [
          "pnpm test"
          "cargo test"
          "pytest"
        ];
      };
    };
  };

  persist.state.homeDirs = [".config/Code" ".config/Cursor" ".cursor"];
  persist.cache.homeDirs = [".wakatime"];
}
