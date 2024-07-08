return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "tsserver", "jdtls" }
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {'hrsh7th/nvim-cmp' },
      {'hrsh7th/cmp-nvim-lsp' },
    },
    config = function()
      local lspconfig = require('lspconfig')
      lspconfig.lua_ls.setup({})
      lspconfig.tsserver.setup({})
      local jdtls_path = vim.fn.stdpath('data') .. "/mason/packages/jdtls"
      local config_dir = jdtls_path .. "/config_linux"
      local plugins_dir = jdtls_path .. "/plugins/"
      local path_to_jar = plugins_dir .. "org.eclipse.equinox.launcher_1.6.600.v20231106-1826.jar"
      local lombok_path = jdtls_path .. "/lombok.jar"
      -- function dump(o)
      --   if type(o) == 'table' then
      --     local s = '{ '
      --     for k,v in pairs(o) do
      --       if type(k) ~= 'number' then k = '"'..k..'"' end
      --       s = s .. '['..k..'] = ' .. dump(v) .. ','
      --     end
      --     return s .. '} '
      --   else
      --     return tostring(o)
      --   end
      -- end
      -- local root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }
      -- print(dump(lspconfig.jdtls))
      -- s="keys: "
      -- for k,v in pairs(lspconfig.jdtls.document_config.commands) do
      --   s = s .. k .. ", "
      -- end
      -- f(s)
      -- print(lspconfig.jdtls.document_config.commands)
      -- local root_dir = lspconfig.jdtls.find_root(root_markers)
      -- if root_dir == "" then
      --   return
      -- end

      local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
      local workspace_dir = vim.fn.stdpath('data') .. '/site/java/workspace-root/' .. project_name
      -- os.execute("mkdir " .. workspace_dir)
      -- Set up nvim-cmp.
      local cmp = require'cmp'

      cmp.setup({
        snippet = {
          -- REQUIRED - you must specify a snippet engine
          expand = function(args)
            vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
            -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
            -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
            -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
          end,
        },
        window = {
          -- completion = cmp.config.window.bordered(),
          -- documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'vsnip' }, -- For vsnip users.
          -- { name = 'luasnip' }, -- For luasnip users.
          -- { name = 'ultisnips' }, -- For ultisnips users.
          -- { name = 'snippy' }, -- For snippy users.
        }, {
            { name = 'buffer' },
          })
      })


      -- Set up lspconfig.
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local config = {
        -- The command that starts the language server
        -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
        cmd = {
          '/home/pvsfair/.sdkman/candidates/java/17.0.7-tem/bin/java',
          '-Declipse.application=org.eclipse.jdt.ls.core.id1',
          '-Dosgi.bundles.defaultStartLevel=4',
          '-Declipse.product=org.eclipse.jdt.ls.core.product',
          '-Dlog.protocol=true',
          '-Dlog.level=ALL',
          '-javaagent:' .. lombok_path,
          '-Xms1g',
          '--add-modules=ALL-SYSTEM',
          '--add-opens', 'java.base/java.util=ALL-UNNAMED',
          '--add-opens', 'java.base/java.lang=ALL-UNNAMED',

          '-jar', path_to_jar,
          '-configuration', config_dir,
          '-data', workspace_dir,
        },
        capabilities = capabilities,

        -- This is the default if not provided, you can remove it. Or adjust as needed.
        -- One dedicated LSP server & client will be started per unique root_dir
        -- root_dir = root_dir,

        -- Here you can configure eclipse.jdt.ls specific settings
        -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
        -- for a list of options
        settings = {
          java = {
            home = '/home/pvsfair/.sdkman/candidates/java/17.0.7-tem/',
            eclipse = {
              downloadSources = true,
            },
            configuration = {
              updateBuildConfiguration = "interactive",
              runtimes = {
                {
                  name = "JavaSE-17",
                  path = "/home/pvsfair/.sdkman/candidates/java/17.0.7-tem/",
                }
              }
            },
            maven = {
              downloadSources = true,
            },
            implementationsCodeLens = {
              enabled = true,
            },
            referencesCodeLens = {
              enabled = true,
            },
            references = {
              includeDecompiledSources = true,
            },
            format = {
              enabled = true,
              settings = {
                url = vim.fn.stdpath "config" .. "/lang-servers/intellij-java-google-style.xml",
                profile = "GoogleStyle",
              },
            },

          },
          signatureHelp = { enabled = true },
          completion = {
            favoriteStaticMembers = {
              "org.hamcrest.MatcherAssert.assertThat",
              "org.hamcrest.Matchers.*",
              "org.hamcrest.CoreMatchers.*",
              "org.junit.jupiter.api.Assertions.*",
              "java.util.Objects.requireNonNull",
              "java.util.Objects.requireNonNullElse",
              "org.mockito.Mockito.*",
            },
            importOrder = {
              "java",
              "javax",
              "com",
              "org"
            },
          },
          sources = {
            organizeImports = {
              starThreshold = 9999,
              staticStarThreshold = 9999,
            },
          },
          codeGeneration = {
            toString = {
              template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
            },
            useBlocks = true,
          },
        },

        flags = {
          allow_incremental_sync = true,
        },
        init_options = {
          bundles = {},
        },
        on_attach = function(client, bufnr)
          require "lsp_signature".on_attach({
            bind = true, -- This is mandatory, otherwise border config won't get registered.
            floating_window_above_cur_line = false,
            padding = '',
            handler_opts = {
              border = "rounded"
            }
          }, bufnr)
        end
      }
      lspconfig.jdtls.setup(config)
    end,
    -- ft = { 'java' },
    keys = {
      { '<leader>sr', function() require('toggleterm').exec("mvn clean quarkus:dev -P.env") end, desc = "Run maven clean quarkus" },
      { '<leader>oi', function() require("jdtls").organize_imports() end, desc = "Organize imports" },
      { '<leader>jc', function() require("jdtls").compile("incremental") end, desc = "Incremental compile (don't know what this does)" },
      { 'K', vim.lsp.buf.hover, desc = "Hover" },
      { 'gD', vim.lsp.buf.declaration, desc = "Go to declaration" },
      { 'gd', vim.lsp.buf.definition, desc = "Go to definition" },
      { 'gi', vim.lsp.buf.implementation, desc = "Go to implementation" },
      { '<space>ca', vim.lsp.buf.code_action, mode = { 'n', 'v' }, desc = "Code action" },
      { '<C-k>', vim.lsp.buf.signature_help, desc = "Signature help" },
      { '<space>rn', vim.lsp.buf.rename, desc = "Rename" },
      { '<space>e', function() vim.diagnostic.open_float(0, {scope="line"}) end, desc = "Show Diagnostic" },
    }
  },
  {
    "artur-shaik/jc.nvim",
    dependencies = {
      {'neovim/nvim-lspconfig'},
      {'hrsh7th/nvim-cmp' },
      {'hrsh7th/cmp-nvim-lsp'},
      {'williamboman/nvim-lsp-installer'},
      -- {'puremourning/vimspector'},
      {'mfussenegger/nvim-jdtls'},
      {'artur-shaik/jc.nvim'},
    },
    config = function()
      require('jc').setup({})
    end
  }
}
