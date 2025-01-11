## [0.10.0](https://github.com/Saghen/blink.cmp/compare/v0.9.3...v0.10.0) (2025-01-08)

### BREAKING CHANGES

* mini.snippets and snippets presets (#877)
* support `preselect` with `auto_insert`, set as default

### Features

* add `get_selected_item` public function ([9e1e7e6](https://github.com/Saghen/blink.cmp/commit/9e1e7e604e3419fa0777a2b747ded74d35013c06))
* mini.snippets and snippets presets ([#877](https://github.com/Saghen/blink.cmp/issues/877)) ([854ab87](https://github.com/Saghen/blink.cmp/commit/854ab87aefdac2b757d97595f98673d64f1878bc))
* set default capabilities on 0.11 ([#897](https://github.com/Saghen/blink.cmp/issues/897)) ([af1febb](https://github.com/Saghen/blink.cmp/commit/af1febb17f9ddc87cf73e69d3f61218cdc18ed85))
* support `preselect` with `auto_insert`, set as default ([8126d0e](https://github.com/Saghen/blink.cmp/commit/8126d0e6a2a0e62d3872d718c3d50313f9f7fe3a)), closes [#668](https://github.com/Saghen/blink.cmp/issues/668)

### Bug Fixes

* `get_char_at_cursor` attempting to get char on empty line ([7d6bf9a](https://github.com/Saghen/blink.cmp/commit/7d6bf9adea67a200067effe5ef589515e71230c8)), closes [#926](https://github.com/Saghen/blink.cmp/issues/926)
* `within_query_bounds` including 1 position after bounds ([36ba8eb](https://github.com/Saghen/blink.cmp/commit/36ba8eb9c166c21d6d2a8b5f88f9c55d1966b383)), closes [#890](https://github.com/Saghen/blink.cmp/issues/890) [#875](https://github.com/Saghen/blink.cmp/issues/875)
* assert vim.lsp.config fn exists before calling ([#927](https://github.com/Saghen/blink.cmp/issues/927)) ([47efef8](https://github.com/Saghen/blink.cmp/commit/47efef83802b26bd2ff7193b24af4c7f747dc145))
* buildVimPlugin ([#933](https://github.com/Saghen/blink.cmp/issues/933)) ([3f5dcbc](https://github.com/Saghen/blink.cmp/commit/3f5dcbc1c28edd2ab31b9bac27cc63de4e56b87c))
* clear context on ignored cursor moved when not on keyword ([0f8de3a](https://github.com/Saghen/blink.cmp/commit/0f8de3abd560f38415d71fc6ee9885c2bf53b814)), closes [#937](https://github.com/Saghen/blink.cmp/issues/937)
* ignore cursor moved when cursor equal before vs after ([17eea33](https://github.com/Saghen/blink.cmp/commit/17eea330a5d111f3cd67f59bb3832cc78f55db14))
* **signature:** use `char_under_cursor` in `on_char_added` handler ([#935](https://github.com/Saghen/blink.cmp/issues/935)) ([275d407](https://github.com/Saghen/blink.cmp/commit/275d40713191e6c0012783ecf762a4faa138098b)), closes [#909](https://github.com/Saghen/blink.cmp/issues/909)

## [0.9.3](https://github.com/Saghen/blink.cmp/compare/v0.9.2...v0.9.3) (2025-01-06)

### Features

* add plaintex, tex and context brackets ([9ffdb7b](https://github.com/Saghen/blink.cmp/commit/9ffdb7b71d0ee9abcccb61d3b8fb60defc4d47ff))
* **path:** replace `/` in front of cursor on directory ([d2b411c](https://github.com/Saghen/blink.cmp/commit/d2b411ca2ec894ccab9d7dc0bd506e44920983ef))

### Bug Fixes

* add .repro to gitignore ([0d1e3c3](https://github.com/Saghen/blink.cmp/commit/0d1e3c34b172bf93380f8675ec962c301f2b5aaa))
* cmdline completion new text not including prefix ([bc480aa](https://github.com/Saghen/blink.cmp/commit/bc480aa927ef4afbf5431f566e8aea7458e9f8df)), closes [#883](https://github.com/Saghen/blink.cmp/issues/883)
* ignore buffer local treesitter option ([d704244](https://github.com/Saghen/blink.cmp/commit/d704244327c1bc1fdd9c0218fe4fff04ca78d3c0)), closes [#913](https://github.com/Saghen/blink.cmp/issues/913)
* ignore non-key char in cmdline completion ([cc0e632](https://github.com/Saghen/blink.cmp/commit/cc0e6329e7603b5749c7fe98a76e39ed17bab860)), closes [#893](https://github.com/Saghen/blink.cmp/issues/893)
* **nix:** use native gcc on macos ([3ab6832](https://github.com/Saghen/blink.cmp/commit/3ab6832b2fc3e49aad9c984089cfc0c5ec788531)), closes [#652](https://github.com/Saghen/blink.cmp/issues/652)
* **nix:** use nix gcc and provide libiconv ([#916](https://github.com/Saghen/blink.cmp/issues/916)) ([5d2d601](https://github.com/Saghen/blink.cmp/commit/5d2d6010d9a5376f9073c1182887e547e3c0ec17))

## [0.9.2](https://github.com/Saghen/blink.cmp/compare/v0.9.1...v0.9.2) (2025-01-03)

### Bug Fixes

* unicode range when checking if char is keyword ([100d3c8](https://github.com/Saghen/blink.cmp/commit/100d3c8bfc8059c2fd2347d00ab70ee91c7ff3ca)), closes [#878](https://github.com/Saghen/blink.cmp/issues/878)

## [0.9.1](https://github.com/Saghen/blink.cmp/compare/v0.9.0...v0.9.1) (2025-01-03)

### Features

* ignore global min_keyword_length for manual trigger ([56f5d31](https://github.com/Saghen/blink.cmp/commit/56f5d314f772617b506d92e46b8e946535edc04e)), closes [#643](https://github.com/Saghen/blink.cmp/issues/643)
* **nix:** add formatter ([#867](https://github.com/Saghen/blink.cmp/issues/867)) ([a0274b1](https://github.com/Saghen/blink.cmp/commit/a0274b10f04ea625b602f6383e3cb2fc38dcfd71)), closes [#736](https://github.com/Saghen/blink.cmp/issues/736)
* normalize search paths ([8a64275](https://github.com/Saghen/blink.cmp/commit/8a64275948cead4de55cd78c7dc74b2c6465605e)), closes [#835](https://github.com/Saghen/blink.cmp/issues/835)
* smarter edit/fuzzy range guessing ([768bcc0](https://github.com/Saghen/blink.cmp/commit/768bcc08282919168cd9bdf29aa8fcbf968fc457)), closes [#46](https://github.com/Saghen/blink.cmp/issues/46)
* sort cmdline items starting with special characters last ([ae3bf0d](https://github.com/Saghen/blink.cmp/commit/ae3bf0d51902df20121378da2ee6893bcc92fa63)), closes [#818](https://github.com/Saghen/blink.cmp/issues/818)
* support custom/customlist cmdline completions directly ([7e7deaa](https://github.com/Saghen/blink.cmp/commit/7e7deaa8bfa578d147e2d1f04a3373fac2afd58f)), closes [#849](https://github.com/Saghen/blink.cmp/issues/849)

### Bug Fixes

* column alignment off by 1 when bounds length == 0 ([0d162bd](https://github.com/Saghen/blink.cmp/commit/0d162bd1b0bbd80a1b5a2dc23d98249d4f8c28f6))
* get full unicode char at cursor position ([e831cab](https://github.com/Saghen/blink.cmp/commit/e831cab7a4c31da02c72044190e9afc1a9ed584c)), closes [#864](https://github.com/Saghen/blink.cmp/issues/864)
* hyphen not being considered a keyword ([8ca8ca4](https://github.com/Saghen/blink.cmp/commit/8ca8ca444e0801411e077cdee655e5efa3f77b36)), closes [#866](https://github.com/Saghen/blink.cmp/issues/866)
* ignore non custom/customlist completion types ([f7857fc](https://github.com/Saghen/blink.cmp/commit/f7857fcb98e52899eb06f07ecb972a430d0de6e0)), closes [#849](https://github.com/Saghen/blink.cmp/issues/849)
* keyword range not being respected for fuzzy matching ([4cc4e37](https://github.com/Saghen/blink.cmp/commit/4cc4e37dd39eec683a9e1a82e71cd1791bda7761))
* path provider not respecting trailing_slash=false ([#862](https://github.com/Saghen/blink.cmp/issues/862)) ([0ff2ed5](https://github.com/Saghen/blink.cmp/commit/0ff2ed566e753844825cd8d2483933861cea55ff))
* set undolevels to force undo point ([4c63b4e](https://github.com/Saghen/blink.cmp/commit/4c63b4e29738268950911bb0c70ffaaba26b53d7)), closes [#852](https://github.com/Saghen/blink.cmp/issues/852)
* use tmp file for downloading to prevent crash on mac on update ([84e065b](https://github.com/Saghen/blink.cmp/commit/84e065bef1504076a0cc3f75f9867b9bce6f328b)), closes [#68](https://github.com/Saghen/blink.cmp/issues/68)
* window direction sorting on Windows ([#846](https://github.com/Saghen/blink.cmp/issues/846)) ([00ad008](https://github.com/Saghen/blink.cmp/commit/00ad008cbea4d0d2b5880e7c7386caa9fc4e5e2b))

### Performance Improvements

* use faster 0.11 vim.validate ([#868](https://github.com/Saghen/blink.cmp/issues/868)) ([a8957ba](https://github.com/Saghen/blink.cmp/commit/a8957bab8faad4436e7ad62244c39335b95450a4))

## [0.9.0](https://github.com/Saghen/blink.cmp/compare/v0.8.2...v0.9.0) (2024-12-31)

### BREAKING CHANGES

* rename `BlinkCmpCompletionMenu*` autocmds to `BlinkCmpMenu*`
* set default documentation max_width to 80
* rename `align_to_component` to `align_to`, add `cursor` option

### Features

* add back support for showing when moving onto trigger character ([cf9cc6e](https://github.com/Saghen/blink.cmp/commit/cf9cc6e43edd2718294ef9801a223c463f50a4ce)), closes [#780](https://github.com/Saghen/blink.cmp/issues/780) [#745](https://github.com/Saghen/blink.cmp/issues/745)
* add callback option to cmp.show ([33b82e5](https://github.com/Saghen/blink.cmp/commit/33b82e5832757319c485ab45c0db4ace554e3183)), closes [#806](https://github.com/Saghen/blink.cmp/issues/806)
* add callback to hide/cancel, rework show callback ([73a5f4e](https://github.com/Saghen/blink.cmp/commit/73a5f4e387ade764a833d290dbb5da77b0d84b4c)), closes [#806](https://github.com/Saghen/blink.cmp/issues/806)
* add type annotation for keymap function params ([#829](https://github.com/Saghen/blink.cmp/issues/829)) ([3d7e773](https://github.com/Saghen/blink.cmp/commit/3d7e773d3e8a02720b23f58ffee631a0c1e2e1d1))
* escape filenames in cmdline ([e53db6a](https://github.com/Saghen/blink.cmp/commit/e53db6a53f85b1c0d56eed66811bfbac520abd6c)), closes [#751](https://github.com/Saghen/blink.cmp/issues/751)
* **nix:** use Cargo.lock instead of hash ([#773](https://github.com/Saghen/blink.cmp/issues/773)) ([d9513ee](https://github.com/Saghen/blink.cmp/commit/d9513ee9f8b111a46e262be2b36172ca335051a2))
* **nix:** use filesets ([#772](https://github.com/Saghen/blink.cmp/issues/772)) ([e524347](https://github.com/Saghen/blink.cmp/commit/e524347697b6664870536dfcdd17e3ab56177b99))
* rename `align_to_component` to `align_to`, add `cursor` option ([9387c75](https://github.com/Saghen/blink.cmp/commit/9387c75af7f8ec1495f4ed5a35cd29f054647dfc)), closes [#344](https://github.com/Saghen/blink.cmp/issues/344)
* rename `BlinkCmpCompletionMenu*` autocmds to `BlinkCmpMenu*` ([fa4312c](https://github.com/Saghen/blink.cmp/commit/fa4312c11f9ab102333f5a18f1a30af5ae636c04))
* run callback for cmp.show, even if menu is open ([a1476d3](https://github.com/Saghen/blink.cmp/commit/a1476d3596f032be3f2d77630c8eee3951d3f74c))
* set default documentation max_width to 80 ([1a61625](https://github.com/Saghen/blink.cmp/commit/1a61625ad2a25c4e1ffffacb4bd0826c244af88f))
* support `@` mode for cmdline ([4c2744d](https://github.com/Saghen/blink.cmp/commit/4c2744d99a13c687e4995fe0a050f40c15dbb2d9)), closes [#696](https://github.com/Saghen/blink.cmp/issues/696)
* support configuring clipboard register for snippets ([8f51a4e](https://github.com/Saghen/blink.cmp/commit/8f51a4ec23773cc96ec6b3ca336a5d70eebb2fb2)), closes [#800](https://github.com/Saghen/blink.cmp/issues/800)
* support unsafe no lock for fuzzy matcher ([6f8da35](https://github.com/Saghen/blink.cmp/commit/6f8da35fc8f1f8046d25b88b7708178cb4126abe)), closes [#817](https://github.com/Saghen/blink.cmp/issues/817)
* support windows drives for path source ([98fded2](https://github.com/Saghen/blink.cmp/commit/98fded25d772a749cbf26e569e735ca7a3fb9d12)), closes [#612](https://github.com/Saghen/blink.cmp/issues/612)
* use filter text on non-prefixed test in cmdline ([8c194b6](https://github.com/Saghen/blink.cmp/commit/8c194b6fa34b174b2ab30ff1d005c6b1b03ba523))

### Bug Fixes

* **accept/brackets:** respect `item.kind` when moving cursor ([#779](https://github.com/Saghen/blink.cmp/issues/779)) ([c54dfbf](https://github.com/Saghen/blink.cmp/commit/c54dfbfdfabac3b5a66ba90c89fab86d7651d106))
* add missing regex file for path source ([1118d07](https://github.com/Saghen/blink.cmp/commit/1118d07c1b720873fe3498a662a265ae8a9a7ee4)), closes [#834](https://github.com/Saghen/blink.cmp/issues/834)
* alignment double offset on align_to ([24d6868](https://github.com/Saghen/blink.cmp/commit/24d6868d0a18bb02cbee7fc5cc2a09fa309e3eb7))
* apply non-snippet detection to non-snippet kinds ([434ea2b](https://github.com/Saghen/blink.cmp/commit/434ea2b05c2bae0cff6249893c8324fa3a56d865)), closes [#790](https://github.com/Saghen/blink.cmp/issues/790)
* avoid namespace collision with vim.api.keyset.keymap ([63718e9](https://github.com/Saghen/blink.cmp/commit/63718e93d46f07b869f033fd13b78597ebbde72b)), closes [#767](https://github.com/Saghen/blink.cmp/issues/767)
* check enabled before showing trigger and on mapping ([e670720](https://github.com/Saghen/blink.cmp/commit/e6707202772be974ae2d54239b806707bb72ccdb)), closes [#716](https://github.com/Saghen/blink.cmp/issues/716)
* clamp text edit end character to start character, if lines equal ([6891bcb](https://github.com/Saghen/blink.cmp/commit/6891bcb06b6f21de68278991f29e53452b822d48)), closes [#634](https://github.com/Saghen/blink.cmp/issues/634)
* create target/release dir, if it doesn't exist ([4020c23](https://github.com/Saghen/blink.cmp/commit/4020c2353b906950cb80be2fc1fabee8a9a9c291)), closes [#819](https://github.com/Saghen/blink.cmp/issues/819)
* documentation losing syntax highlighting on doc reopen ([#768](https://github.com/Saghen/blink.cmp/issues/768)) ([ef59763](https://github.com/Saghen/blink.cmp/commit/ef59763c8a58fb1dedfb2d58a2ebd0fbe247f96c)), closes [#703](https://github.com/Saghen/blink.cmp/issues/703)
* don't prevent show() when ghost-text is visible ([#796](https://github.com/Saghen/blink.cmp/issues/796)) ([59d6b4f](https://github.com/Saghen/blink.cmp/commit/59d6b4fbe94cfc350b1392772a61cbcf942619c7))
* filter help tags by arg prefix ([21da714](https://github.com/Saghen/blink.cmp/commit/21da71413bf749f21d2174c1cd7e8efa40809a93)), closes [#818](https://github.com/Saghen/blink.cmp/issues/818)
* flatten leaving empty tables ([#799](https://github.com/Saghen/blink.cmp/issues/799)) ([021216d](https://github.com/Saghen/blink.cmp/commit/021216da4683db5627d4b321dbde075aa771b5e7))
* getcmdcompltype returning empty string ([eb9e651](https://github.com/Saghen/blink.cmp/commit/eb9e651bca40bbfb4de2a77a293a1e18bb373ee8)), closes [#696](https://github.com/Saghen/blink.cmp/issues/696)
* remove redundant is enabled check ([f4add54](https://github.com/Saghen/blink.cmp/commit/f4add54f999962e6385d42bad341366b85184217))
* return incomplete on err/nil from lsp ([1ef9bb9](https://github.com/Saghen/blink.cmp/commit/1ef9bb97740e7b55401e213da5dd6b04b77e56ff)), closes [#719](https://github.com/Saghen/blink.cmp/issues/719)
* set default details to empty array ([0350fee](https://github.com/Saghen/blink.cmp/commit/0350feedfa8adb07b6750f6d9150c26e13eae0d2))
* trigger context initial_kind resetting ([3ef27bc](https://github.com/Saghen/blink.cmp/commit/3ef27bcd7ff2367c6053421d4a8981bedc33d53e)), closes [#803](https://github.com/Saghen/blink.cmp/issues/803)
* use correct regex for filenames ([8df826f](https://github.com/Saghen/blink.cmp/commit/8df826f168f102d0fbea92cbd85995ce66a821c7)), closes [#761](https://github.com/Saghen/blink.cmp/issues/761)
* use existing arg prefix for help filtering in cmdline ([c593e83](https://github.com/Saghen/blink.cmp/commit/c593e8385d9f8f82a6e108fbabcd1f64fce72684))
* wait for all LSPs to respond before showing ([86a13ae](https://github.com/Saghen/blink.cmp/commit/86a13aeb104d6ea782557518ee1a350712df7bd7)), closes [#691](https://github.com/Saghen/blink.cmp/issues/691)

## [0.8.2](https://github.com/Saghen/blink.cmp/compare/v0.8.1...v0.8.2) (2024-12-23)

### Features

* improve auto_show flexibility ([#697](https://github.com/Saghen/blink.cmp/issues/697)) ([a937edd](https://github.com/Saghen/blink.cmp/commit/a937edde979a8ff140779fa0d425af566bc73cb7))
* improve error messages for pre built binaries ([c36b60c](https://github.com/Saghen/blink.cmp/commit/c36b60c22f7357d741c9166e4d509b745cc8b441))
* sort cmdline completions case insensitive ([b68e924](https://github.com/Saghen/blink.cmp/commit/b68e92426af46d60f08a4d2f58ed1e44d4e56087)), closes [#715](https://github.com/Saghen/blink.cmp/issues/715)
* support dynamic selection mode ([c1017f0](https://github.com/Saghen/blink.cmp/commit/c1017f0a827736e3397f9b60dfe8e8ebb4a0ae72))

### Bug Fixes

* add git to nix build dependencies and shell ([ed1d4f5](https://github.com/Saghen/blink.cmp/commit/ed1d4f573f8988353d6e437f5e70ee334ea099fe))
* add java to blocked filetypes for semantic token auto_brackets ([#729](https://github.com/Saghen/blink.cmp/issues/729)) ([140ed36](https://github.com/Saghen/blink.cmp/commit/140ed3633419965e8f2228af0d5fbaa4c1956f78))
* add missing git.lua for downloader ([f7bef25](https://github.com/Saghen/blink.cmp/commit/f7bef25052820d4d7604a296c739ba9d885117f8))
* auto_show function logic ([#707](https://github.com/Saghen/blink.cmp/issues/707)) ([4ef6d1e](https://github.com/Saghen/blink.cmp/commit/4ef6d1ee29e8ae9138a47bba9374b7c0c97452b6)), closes [#697](https://github.com/Saghen/blink.cmp/issues/697)
* check version sha of locally built, better detection ([3ffd31d](https://github.com/Saghen/blink.cmp/commit/3ffd31d0c52a51d064f4761d5c0bfad64129c1e9)), closes [#68](https://github.com/Saghen/blink.cmp/issues/68)
* doc scrollbar render ([#724](https://github.com/Saghen/blink.cmp/issues/724)) ([8f71ccb](https://github.com/Saghen/blink.cmp/commit/8f71ccbe668860a4ebcaed3928d80d2119559ad9))
* inherit package.cpath in worker thread ([#726](https://github.com/Saghen/blink.cmp/issues/726)) ([b6c7762](https://github.com/Saghen/blink.cmp/commit/b6c7762407b6c4521b46244f35fab05cfd1c6863)), closes [#725](https://github.com/Saghen/blink.cmp/issues/725)
* **notifications:** add title to notifications ([#722](https://github.com/Saghen/blink.cmp/issues/722)) ([f93af0f](https://github.com/Saghen/blink.cmp/commit/f93af0f486ada13e8c34f42c911788b9232b811f))
* prebuilt binary error message always firing ([cab0e8e](https://github.com/Saghen/blink.cmp/commit/cab0e8e169a2c595018f9fdb981e056094bd5aeb))

## [0.8.1](https://github.com/Saghen/blink.cmp/compare/v0.8.0...v0.8.1) (2024-12-21)

### Features

* **path:** sort directories first, then by name lowercase ([400de65](https://github.com/Saghen/blink.cmp/commit/400de65da795b5939ace36978de3d1edeb84b0de))

### Bug Fixes

* checkhealth after checksum changes ([d8ffbe9](https://github.com/Saghen/blink.cmp/commit/d8ffbe95190a776c6a28c86650efcbc23c5f6521)), closes [#669](https://github.com/Saghen/blink.cmp/issues/669)
* duplicate cursor moved event firing ([e360828](https://github.com/Saghen/blink.cmp/commit/e360828a188dc30658067eac63feded08857c076))
* get global mapping for fallback in cmdline mode ([92da013](https://github.com/Saghen/blink.cmp/commit/92da0133b240e60100fcb04b32fcd7270f765d94)), closes [#674](https://github.com/Saghen/blink.cmp/issues/674)
* internal types for config not using strict config ([bdece4e](https://github.com/Saghen/blink.cmp/commit/bdece4e90e70baee956e2351220527a619d25052))
* **path:** no items when file fails stat ([4218120](https://github.com/Saghen/blink.cmp/commit/421812086661bba3aa318030eee12719fc5da072)), closes [#688](https://github.com/Saghen/blink.cmp/issues/688)
* type signature for enabled indicating ctx could be passed ([3cb7208](https://github.com/Saghen/blink.cmp/commit/3cb7208546b4e1f0c5e492cbcfccd083a1c89351)), closes [#695](https://github.com/Saghen/blink.cmp/issues/695)
* use context.get_line() when getting preview undo text edit ([0f92fb8](https://github.com/Saghen/blink.cmp/commit/0f92fb8dcff634e880a60e266f041dfe175b82bf)), closes [#702](https://github.com/Saghen/blink.cmp/issues/702)
* wrong key upstreamed by cmdline_events ([4757317](https://github.com/Saghen/blink.cmp/commit/475731741bbd8266767d48ad46b63f715577ac8e)), closes [#700](https://github.com/Saghen/blink.cmp/issues/700)

## [0.8.0](https://github.com/Saghen/blink.cmp/compare/v0.7.6...v0.8.0) (2024-12-20)

> [!IMPORTANT]
> `sources.completion.enabled_providers` has been moved to `sources.default`

### Highlights

* Cmdline completions! ([#323](https://github.com/Saghen/blink.cmp/issues/323))
* Sorting now respects LSP hints more directly and doesn't sort alphabetically or by kind by default 
* Sources v2 ([#465](https://github.com/Saghen/blink.cmp/issues/465)), adds support for async sources, timeouts, smarter fallbacks, adding sources at runtime and more!

### Features

* `extra_curl_args` option for prebuilt binaries download ([4c2e9e7](https://github.com/Saghen/blink.cmp/commit/4c2e9e74905502e3662fbd4af7b0d1b680971a04)), closes [#481](https://github.com/Saghen/blink.cmp/issues/481)
* add [ to show_on_x_blocked_trigger_characters ([#632](https://github.com/Saghen/blink.cmp/issues/632)) ([046a2af](https://github.com/Saghen/blink.cmp/commit/046a2af7580ba90cda9ffebbab3f1fe68ca1fa59))
* add `{` to `show_on_x_blocked_trigger_characters` ([712bd30](https://github.com/Saghen/blink.cmp/commit/712bd301fc2158e6443144ff9c8ce01b8bf5a77b)), closes [#597](https://github.com/Saghen/blink.cmp/issues/597)
* add global transform_items and min_keyword_length ([e07cb27](https://github.com/Saghen/blink.cmp/commit/e07cb2756d5cc339dfa4bf4d9bc91b3779dbb743)), closes [#502](https://github.com/Saghen/blink.cmp/issues/502) [#504](https://github.com/Saghen/blink.cmp/issues/504)
* allow providers customize documentation rendering ([#650](https://github.com/Saghen/blink.cmp/issues/650)) ([bc94c75](https://github.com/Saghen/blink.cmp/commit/bc94c7508379b4828206759562162ce10af82b68))
* cmdline completions ([#323](https://github.com/Saghen/blink.cmp/issues/323)) ([414d615](https://github.com/Saghen/blink.cmp/commit/414d615afcd9268522160dca5855fef8132f6e9e))
* **cmdline:** allow configuring separate cmdline preset ([#532](https://github.com/Saghen/blink.cmp/issues/532)) ([13b3e57](https://github.com/Saghen/blink.cmp/commit/13b3e572e863bafe8fad3a97473271a2c9c700ce))
* **config:** add partial types for each config option ([#549](https://github.com/Saghen/blink.cmp/issues/549)) ([c3bba64](https://github.com/Saghen/blink.cmp/commit/c3bba64d6c32adf4156e9d1273b14494838a3058)), closes [#427](https://github.com/Saghen/blink.cmp/issues/427)
* **config:** allow plugins to disable blink for some buffers ([#556](https://github.com/Saghen/blink.cmp/issues/556)) ([c8e86a3](https://github.com/Saghen/blink.cmp/commit/c8e86a3ed1eff07e2c1108779a720d3b4c6b86a7))
* demote snippets from LSP explicitly ([b7c84ac](https://github.com/Saghen/blink.cmp/commit/b7c84ac4e17f3e160a626a9a89b609e02151a135))
* disable keymaps when no cmdline sources are defined ([88ec601](https://github.com/Saghen/blink.cmp/commit/88ec6010ddbb249257d22265b8a96842f10c7142))
* enable auto-brackets by default ([4d099ee](https://github.com/Saghen/blink.cmp/commit/4d099eeb72cfbd6496376fbb3265a1887a7c85fe))
* enable treesiter highlight in menu per source ([#526](https://github.com/Saghen/blink.cmp/issues/526)) ([f99b03c](https://github.com/Saghen/blink.cmp/commit/f99b03c756b32680eea28e89f95e3c6987cc6c80)), closes [#438](https://github.com/Saghen/blink.cmp/issues/438)
* ensure nvim 0.10+ on startup ([30a4a52](https://github.com/Saghen/blink.cmp/commit/30a4a52d2362e3a272ae1cf28552852ae09b38a9))
* expose `cmp.is_visible()` api ([2c826d9](https://github.com/Saghen/blink.cmp/commit/2c826d9167c7236f6079790bc35bcb024021e683)), closes [#535](https://github.com/Saghen/blink.cmp/issues/535)
* filter out LSP text items by default ([814392a](https://github.com/Saghen/blink.cmp/commit/814392a7164336fe5fbd6d4b97a69dce9eb6e4ef))
* honor extended luasnip filetypes and cache each ([#625](https://github.com/Saghen/blink.cmp/issues/625)) ([c3ef922](https://github.com/Saghen/blink.cmp/commit/c3ef9223a69ededed611b3ef617bac5651b87833))
* ignore when source defining trigger character returns no items ([684950d](https://github.com/Saghen/blink.cmp/commit/684950d3c4027e10a46f4bd478182839760b8fde)), closes [#597](https://github.com/Saghen/blink.cmp/issues/597)
* include ghost text in is_visible ([1006662](https://github.com/Saghen/blink.cmp/commit/1006662ad53c92adf9ae6f2d05cee38f613d08ff))
* increase max length of buffer entry to 512 characters ([4ab0860](https://github.com/Saghen/blink.cmp/commit/4ab0860d361234e714d3beac2828d215f3f481e1)), closes [#478](https://github.com/Saghen/blink.cmp/issues/478)
* merge resolved item with item ([7a83acf](https://github.com/Saghen/blink.cmp/commit/7a83acf5b3cba829b07a05009866548c8e948ac0)), closes [#553](https://github.com/Saghen/blink.cmp/issues/553)
* reset whole luasnip cache on snippets added ([bff6c0f](https://github.com/Saghen/blink.cmp/commit/bff6c0f06bdc1114c5816b0f6b19ad6a7e15a638))
* resolve help tags ourselves in cmdline ([02051bf](https://github.com/Saghen/blink.cmp/commit/02051bf2d9c8f116680659f091b510598a4aea38)), closes [#631](https://github.com/Saghen/blink.cmp/issues/631)
* rework cmdline source ([8f718cc](https://github.com/Saghen/blink.cmp/commit/8f718cc0d845348fd19c964aa6a82b06ea49c210))
* rework download logic with checksums ([#629](https://github.com/Saghen/blink.cmp/issues/629)) ([53d22cb](https://github.com/Saghen/blink.cmp/commit/53d22cbac470b5ed8bfa2c3c195b82e03b501629))
* set cursor position for additional text edits ([f0ab5e5](https://github.com/Saghen/blink.cmp/commit/f0ab5e504b160d4bc60f52a02e8d2453052420d3)), closes [#223](https://github.com/Saghen/blink.cmp/issues/223)
* set path to fallback to buffer by default ([c9594d5](https://github.com/Saghen/blink.cmp/commit/c9594d5682ca421ee1bcb4284329f2d7dde71b50))
* sort on score and sort_text only by default, disable frecency and proximity on no keyword ([76230d5](https://github.com/Saghen/blink.cmp/commit/76230d5a4a02cd1db8dec33b6eed0b4bc2dcbc53)), closes [#570](https://github.com/Saghen/blink.cmp/issues/570)
* sources v2 ([#465](https://github.com/Saghen/blink.cmp/issues/465)) ([533608f](https://github.com/Saghen/blink.cmp/commit/533608f56b912aba98250a3c1501ee687d7cf5eb)), closes [#386](https://github.com/Saghen/blink.cmp/issues/386) [#219](https://github.com/Saghen/blink.cmp/issues/219) [#328](https://github.com/Saghen/blink.cmp/issues/328) [#331](https://github.com/Saghen/blink.cmp/issues/331) [#312](https://github.com/Saghen/blink.cmp/issues/312) [#454](https://github.com/Saghen/blink.cmp/issues/454) [#444](https://github.com/Saghen/blink.cmp/issues/444) [#372](https://github.com/Saghen/blink.cmp/issues/372) [#475](https://github.com/Saghen/blink.cmp/issues/475)
* support callback on `cmp.accept()` ([be3e9cf](https://github.com/Saghen/blink.cmp/commit/be3e9cf435588b3ff4de7abcb04ec90c812f1871))
* support configuring prefetch_on_insert, disable by default ([9d4286f](https://github.com/Saghen/blink.cmp/commit/9d4286f9a410af788ee8406ec45e268aa4b23c9f))
* **trigger:** prefetch on InsertEnter ([#507](https://github.com/Saghen/blink.cmp/issues/507)) ([7e98665](https://github.com/Saghen/blink.cmp/commit/7e9866529768065e0e191e436fc60220bef5185e))
* use block icon for tailwind items ([#544](https://github.com/Saghen/blink.cmp/issues/544)) ([1502c75](https://github.com/Saghen/blink.cmp/commit/1502c754b9c241eecab1393d74a4eb6ccdfe0e64))
* use number[] for ui_cmdline_pos ([80a5198](https://github.com/Saghen/blink.cmp/commit/80a5198a357ddcee97d94ac2be9a3590cd5a63f5))
* validate config doesn't have erroneous fields ([834163e](https://github.com/Saghen/blink.cmp/commit/834163eebdfdb1ca2a4a54b1e8d4c8d2c8184c12)), closes [#501](https://github.com/Saghen/blink.cmp/issues/501)
* **window:** add `filetype` configuration ([#499](https://github.com/Saghen/blink.cmp/issues/499)) ([eb6213b](https://github.com/Saghen/blink.cmp/commit/eb6213b974e604f9ef8560e6c2379d757e81954d))

### Bug Fixes

* **accept:** schecule `fuzzy.access` using uv.new_work ([#522](https://github.com/Saghen/blink.cmp/issues/522)) ([f66f19c](https://github.com/Saghen/blink.cmp/commit/f66f19c864e68ee5e2fb452648b7f6995ddadaa3))
* account for cmdheight in cmdline_position (thanks [@lnrds](https://github.com/lnrds)!) ([6b67d16](https://github.com/Saghen/blink.cmp/commit/6b67d16036b780f49e44d3f5de207d3c7301f3e4)), closes [#538](https://github.com/Saghen/blink.cmp/issues/538)
* add '=' to cmdline trigger characters ([fb03ca7](https://github.com/Saghen/blink.cmp/commit/fb03ca7dd41fc5c234bf5ec089568f4eae584efb)), closes [#541](https://github.com/Saghen/blink.cmp/issues/541)
* add back, skip undo point for snippet kinds ([1563079](https://github.com/Saghen/blink.cmp/commit/15630796fc8c3c45c345d2fe73de6b3a1dc9bb11))
* add gcc to flake.nix ([380bccf](https://github.com/Saghen/blink.cmp/commit/380bccf6eb1e3135fbab986f54aabd9147ff5977)), closes [#581](https://github.com/Saghen/blink.cmp/issues/581)
* add icon gap on ellipsis, remove references to renderer ([793b6ac](https://github.com/Saghen/blink.cmp/commit/793b6ac94efe754d31299b7de2e953244fe0d4ab))
* add mode to context type ([f1afb8c](https://github.com/Saghen/blink.cmp/commit/f1afb8c77686ba6f5159dcb7591bf21efcc5f410))
* allow 'none' preset for keymaps in validation ([bf1fd6a](https://github.com/Saghen/blink.cmp/commit/bf1fd6a690882a9bf5e07ded70fb3bba5d8a5bdf))
* always get latest keyword ([13853d5](https://github.com/Saghen/blink.cmp/commit/13853d5c9cf827fc051fa7adebe701cce2ecd22f)), closes [#539](https://github.com/Saghen/blink.cmp/issues/539)
* check raw key for space in cmdline_events ([7be970e](https://github.com/Saghen/blink.cmp/commit/7be970e278334482710e1f37936c8480b522a751))
* check that scrollbar is not nil ([790369b](https://github.com/Saghen/blink.cmp/commit/790369bb9998d1f9a01f67378e407622b492cf69)), closes [#525](https://github.com/Saghen/blink.cmp/issues/525)
* clear LuaSnip cache on snippet updates ([#664](https://github.com/Saghen/blink.cmp/issues/664)) ([b1b58e7](https://github.com/Saghen/blink.cmp/commit/b1b58e7b9895f43e64891346f76238d697aaadb9))
* cmdline event suppression and scrollbar rendering ([e3b3fde](https://github.com/Saghen/blink.cmp/commit/e3b3fdedbc14afe7361228f7d2c8ce84cee272a6)), closes [#523](https://github.com/Saghen/blink.cmp/issues/523)
* cmdline events firing cursor moved when changed ([97989c8](https://github.com/Saghen/blink.cmp/commit/97989c8ee257239566c4d08264b080703ccc923b)), closes [#520](https://github.com/Saghen/blink.cmp/issues/520)
* cmdline including current arg prefix ([49bff2b](https://github.com/Saghen/blink.cmp/commit/49bff2bf23f15ae31a245e9ffd1b79a9f95bed61)), closes [#609](https://github.com/Saghen/blink.cmp/issues/609)
* **cmdline:** not delete buf when hide scrollbar cause it seems not necessary ([#591](https://github.com/Saghen/blink.cmp/issues/591)) ([0046d0c](https://github.com/Saghen/blink.cmp/commit/0046d0cc3e9bdd2dc36c2ec7a79aee32e76afa73))
* completion auto_insert replace incorrect range ([#621](https://github.com/Saghen/blink.cmp/issues/621)) ([5926869](https://github.com/Saghen/blink.cmp/commit/59268691492bc1abfb0ed91a1cb3ac9fcc01650c)), closes [#460](https://github.com/Saghen/blink.cmp/issues/460)
* **completion:** disable in prompt buffers ([#574](https://github.com/Saghen/blink.cmp/issues/574)) ([1097d4e](https://github.com/Saghen/blink.cmp/commit/1097d4e24909c5b1a15b1ac6907ec26f78f5d22c))
* consider functions as snippet commands ([d065c87](https://github.com/Saghen/blink.cmp/commit/d065c87b59a301065f863134d3a8271bdff6f630))
* disable ghost text in command mode ([ad17735](https://github.com/Saghen/blink.cmp/commit/ad17735a6ddb4255cad6f0af574150761baf5ee4)), closes [#524](https://github.com/Saghen/blink.cmp/issues/524)
* don't block trigger characters in command mode ([0a729ae](https://github.com/Saghen/blink.cmp/commit/0a729ae1c4ab48695fb327161768720a82ed698f)), closes [#541](https://github.com/Saghen/blink.cmp/issues/541)
* don't create undo point when kind equals snippet ([343e89d](https://github.com/Saghen/blink.cmp/commit/343e89d39deb14b5cc6de844ce069ae3d98d7403))
* don't duplicate `.` when completing hidden files in path source ([#557](https://github.com/Saghen/blink.cmp/issues/557)) ([714e2b5](https://github.com/Saghen/blink.cmp/commit/714e2b5f3fdcabd6ad31f98c71f930b260644c72))
* don't show when moving on trigger character, hide on no items after trigger ([7a04612](https://github.com/Saghen/blink.cmp/commit/7a046122de512db8194dae130d691526b5031456)), closes [#545](https://github.com/Saghen/blink.cmp/issues/545)
* duplicate snippets in luasnip when autosnippets are enabled ([12ffc10](https://github.com/Saghen/blink.cmp/commit/12ffc10c6283ac148a89d72b5540d819fc80e2ff))
* fire cursor moved when jumping between tab stops in a snippet ([1e4808e](https://github.com/Saghen/blink.cmp/commit/1e4808e3429bc060fa538728115edcaebbfc5c35)), closes [#545](https://github.com/Saghen/blink.cmp/issues/545)
* **fuzzy:** initialize db only once ([7868d47](https://github.com/Saghen/blink.cmp/commit/7868d477018f73bff6ca60757c1171223084bd12))
* **ghost_text:** correctly disable on cmdline ([54d1a98](https://github.com/Saghen/blink.cmp/commit/54d1a980595e056e7be45a10d1cc8c34159f6d74))
* ignore snippets that only contain text ([284dd37](https://github.com/Saghen/blink.cmp/commit/284dd37f9bbc632f8281d6361e877db5b45e6ff0)), closes [#624](https://github.com/Saghen/blink.cmp/issues/624)
* ignore sort_text if either are nil ([3ba583c](https://github.com/Saghen/blink.cmp/commit/3ba583cedb321291f3145b6e85039ed315b06b17)), closes [#595](https://github.com/Saghen/blink.cmp/issues/595)
* include space for cmdline events ([38b9c4f](https://github.com/Saghen/blink.cmp/commit/38b9c4f36a815fd3d9094e6d5c236a83dbb68ff9))
* incorrect bounds when removing word under cursor in buffer sources ([d682165](https://github.com/Saghen/blink.cmp/commit/d6821651b145c730ca59faee638947a067243b24)), closes [#560](https://github.com/Saghen/blink.cmp/issues/560)
* **keymap:** incorrect merging strategy ([f88bd66](https://github.com/Saghen/blink.cmp/commit/f88bd66d88e9248276996c0f5b5c2b7fa5aa851f)), closes [#599](https://github.com/Saghen/blink.cmp/issues/599)
* **keymap:** normalize mapping capitalization ([#599](https://github.com/Saghen/blink.cmp/issues/599)) ([596a7ab](https://github.com/Saghen/blink.cmp/commit/596a7ab89cca7cdcddc0422e8f5a449042b7ff80))
* **luasnip:** add global_snippets with ft="all" ([#546](https://github.com/Saghen/blink.cmp/issues/546)) ([9f1fb75](https://github.com/Saghen/blink.cmp/commit/9f1fb75b3ec282253ce6392360a584d0234904d0))
* on_key for cmdline events ([89479f3](https://github.com/Saghen/blink.cmp/commit/89479f3f4c9096330a321a6cc438f5bc3f1e596b)), closes [#534](https://github.com/Saghen/blink.cmp/issues/534)
* prefetch first item when selection == 'manual' | 'auto_insert' ([a8222cf](https://github.com/Saghen/blink.cmp/commit/a8222cf1ccbf24818ae926f94779267659809ab0)), closes [#627](https://github.com/Saghen/blink.cmp/issues/627)
* **provider:** add missing validations ([#516](https://github.com/Saghen/blink.cmp/issues/516)) ([1eda2b9](https://github.com/Saghen/blink.cmp/commit/1eda2b989213b54a66589b44236bfcb427c9a5fe))
* **provider:** restore path completion source ([#506](https://github.com/Saghen/blink.cmp/issues/506)) ([b2d13ba](https://github.com/Saghen/blink.cmp/commit/b2d13ba7a0aa6f53d3b0db2cd5ede7827ec72f5b)), closes [#465](https://github.com/Saghen/blink.cmp/issues/465)
* re-enable scrollbar on menu ([d48bb17](https://github.com/Saghen/blink.cmp/commit/d48bb176ae3a8d2f3fa4240f9098b94f1f0947ca)), closes [#519](https://github.com/Saghen/blink.cmp/issues/519)
* remove vim.notify on snippet only containing text ([59ef8a4](https://github.com/Saghen/blink.cmp/commit/59ef8a45eeafef35d8196473d86acbe515116027))
* respect opts.index when checking if cmp.accept can be run ([ea12c51](https://github.com/Saghen/blink.cmp/commit/ea12c516ef43f14683903064bad7612d6e6a6a02)), closes [#633](https://github.com/Saghen/blink.cmp/issues/633)
* revert enabled logic or ([cfd1b7f](https://github.com/Saghen/blink.cmp/commit/cfd1b7f1b24ed77049d978c0a8813097a6e3acc7)), closes [#574](https://github.com/Saghen/blink.cmp/issues/574) [#577](https://github.com/Saghen/blink.cmp/issues/577)
* run callback when LSP client returns nil ([f9b72e3](https://github.com/Saghen/blink.cmp/commit/f9b72e3c1a1b61984b9128fb3e024fdf8a3d07fa)), closes [#543](https://github.com/Saghen/blink.cmp/issues/543)
* schedule get_bufnrs for buffer source ([342c5ed](https://github.com/Saghen/blink.cmp/commit/342c5ed6336d2850c59937747daccb4e880319e0))
* signature help window documentation rendering ([264aea4](https://github.com/Saghen/blink.cmp/commit/264aea42fb2de42a377ae573141cfb61ab849f47))
* sort by sortText/label again ([30705ab](https://github.com/Saghen/blink.cmp/commit/30705aba472b5c67b3a34d84f40d36add75b4c44)), closes [#444](https://github.com/Saghen/blink.cmp/issues/444)
* **sources:** set default item kind to `Property` ([#505](https://github.com/Saghen/blink.cmp/issues/505)) ([08ff824](https://github.com/Saghen/blink.cmp/commit/08ff824de4b76d314f7871e0345f7990b3faccb4))
* **tailwind:** color rendering ([#601](https://github.com/Saghen/blink.cmp/issues/601)) ([02528e8](https://github.com/Saghen/blink.cmp/commit/02528e8ccbe4d0cef5e1df52eda419c5ed557ad3))
* uncomment event emitter autocmd ([e1cf25f](https://github.com/Saghen/blink.cmp/commit/e1cf25fea50593993777865b3cca1db556a4a90b))
* use luasnip get_snippet_filetypes, remove global_snippets option ([c0b5ae9](https://github.com/Saghen/blink.cmp/commit/c0b5ae940d7516eb07ca499f5a46445f216c46d3)), closes [#603](https://github.com/Saghen/blink.cmp/issues/603)
* use transform_items on resolve ([85176f7](https://github.com/Saghen/blink.cmp/commit/85176f7e3264b8ac3b571db12191416a4dce0303)), closes [#614](https://github.com/Saghen/blink.cmp/issues/614)

## [0.7.5](https://github.com/Saghen/blink.cmp/compare/v0.7.4...v0.7.5) (2024-12-10)

### Features

* use `enabled` function instead of blocked_filetypes ([a6636c1](https://github.com/Saghen/blink.cmp/commit/a6636c1c38704c1581750b29abb0addabd198b89)), closes [#440](https://github.com/Saghen/blink.cmp/issues/440)

### Bug Fixes

* **fallback:** make fallback work with buffer-local mappings ([#483](https://github.com/Saghen/blink.cmp/issues/483)) ([8b553f6](https://github.com/Saghen/blink.cmp/commit/8b553f65419d051fe84eeeda3e2071e104c4f272))

## [0.7.4](https://github.com/Saghen/blink.cmp/compare/v0.7.3...v0.7.4) (2024-12-09)

### Features

* support non-latin characters for keyword and buffer source ([51d5f59](https://github.com/Saghen/blink.cmp/commit/51d5f598adf7f1cd1bb188011bb761c1856083a9)), closes [#130](https://github.com/Saghen/blink.cmp/issues/130) [#388](https://github.com/Saghen/blink.cmp/issues/388)

### Bug Fixes

* check response.err instead of response.error ([#473](https://github.com/Saghen/blink.cmp/issues/473)) ([e720477](https://github.com/Saghen/blink.cmp/commit/e7204774a6e99c5e222c930565353c757d2d0ec1))
* completion.trigger.show_in_snippet ([#452](https://github.com/Saghen/blink.cmp/issues/452)) ([a42afb6](https://github.com/Saghen/blink.cmp/commit/a42afb61ad455816aef6baa1992f8de45e9a5eb1)), closes [#443](https://github.com/Saghen/blink.cmp/issues/443)
* documentation window auto show once and for all ([624676e](https://github.com/Saghen/blink.cmp/commit/624676efda13aa78a042aba29ee13e109821fa76)), closes [#430](https://github.com/Saghen/blink.cmp/issues/430)
* fill in cargoHash ([aa70277](https://github.com/Saghen/blink.cmp/commit/aa70277f537c942f7e477fd135531fffc37d81f3))
* **highlight:** fix invalid highlight for doc separator ([#449](https://github.com/Saghen/blink.cmp/issues/449)) ([283a6af](https://github.com/Saghen/blink.cmp/commit/283a6afee44e0aea9b17074d49779558354d3520))
* luasnip resolve documentation ([85f318b](https://github.com/Saghen/blink.cmp/commit/85f318b6db5b48d825d4ef575b405a8d41233753)), closes [#437](https://github.com/Saghen/blink.cmp/issues/437)
* make buffer events options required ([d0b0e16](https://github.com/Saghen/blink.cmp/commit/d0b0e16671733432986953bf4ddff268eb5b2d7c))
* **render:** not render two separator for doc window ([#451](https://github.com/Saghen/blink.cmp/issues/451)) ([fc12fa9](https://github.com/Saghen/blink.cmp/commit/fc12fa99d4e1274d331c2004e777981193f7d6f8))
* revert luasnip source to use current cursor position ([5cfff34](https://github.com/Saghen/blink.cmp/commit/5cfff3433a2afc3f4e29eb4e3caa8f80953f0cfb))

## [0.7.3](https://github.com/Saghen/blink.cmp/compare/v0.7.2...v0.7.3) (2024-12-03)

### Bug Fixes

* revert to original logic for updating menu position ([99129b6](https://github.com/Saghen/blink.cmp/commit/99129b67759c1b78198e527eae9cc91121cded29)), closes [#436](https://github.com/Saghen/blink.cmp/issues/436)

## [0.7.2](https://github.com/Saghen/blink.cmp/compare/v0.7.1...v0.7.2) (2024-12-03)

> [!IMPORTANT]
> A native `luasnip` source has been added, please see the [README](https://github.com/Saghen/blink.cmp#luasnip) for the configuration

### Features

* add `auto_show` property for menu ([29fe017](https://github.com/Saghen/blink.cmp/commit/29fe017624030fa53ee053626762fa385a9adb19)), closes [#402](https://github.com/Saghen/blink.cmp/issues/402)
* clamp text edit range to bounds ([7ceff61](https://github.com/Saghen/blink.cmp/commit/7ceff61595aae682b421a68e208719b1523c7b44)), closes [#257](https://github.com/Saghen/blink.cmp/issues/257)
* expose reload function ([f4e53f2](https://github.com/Saghen/blink.cmp/commit/f4e53f2ac7a3d8c3ef47be0dffa97dca637bf696)), closes [#428](https://github.com/Saghen/blink.cmp/issues/428)
* native luasnip source ([08b59ed](https://github.com/Saghen/blink.cmp/commit/08b59edc59950be279f8c72a20bd7897e9f0d021)), closes [#378](https://github.com/Saghen/blink.cmp/issues/378) [#401](https://github.com/Saghen/blink.cmp/issues/401) [#432](https://github.com/Saghen/blink.cmp/issues/432)

### Bug Fixes

* avoid removing words for current line on out of focus buffers ([2cbb02d](https://github.com/Saghen/blink.cmp/commit/2cbb02da58ab40f2bfd3dd85f80cba76d6279987)), closes [#433](https://github.com/Saghen/blink.cmp/issues/433)
* documentation not updating after manually opened ([8c1fdc9](https://github.com/Saghen/blink.cmp/commit/8c1fdc901cfead1cd88ed3e652d45ca7d75a3d3f)), closes [#430](https://github.com/Saghen/blink.cmp/issues/430)
* handle nil line ([#429](https://github.com/Saghen/blink.cmp/issues/429)) ([38b3ad6](https://github.com/Saghen/blink.cmp/commit/38b3ad6d4af9d392d3e5e0dabcb14e7d8e348314))

## [0.7.1](https://github.com/Saghen/blink.cmp/compare/v0.7.0...v0.7.1) (2024-12-02)

### Bug Fixes

* arguments on curl ([f992b72](https://github.com/Saghen/blink.cmp/commit/f992b72017cac77d4f4e22dc05016e5d79adff68))
* drop retry from curl ([6e9fb62](https://github.com/Saghen/blink.cmp/commit/6e9fb6254bb49eaf014a48049ff511bbfd6a66a3)), closes [#425](https://github.com/Saghen/blink.cmp/issues/425)

## [0.7.0](https://github.com/Saghen/blink.cmp/compare/v0.6.2...v0.7.0) (2024-12-02)

> [!IMPORTANT]
> Most of the configuration has been reworked, please see the README for the new schema

* Includes an enormous refactor in preparation for sources v2, commandline completions, and the v1 release [#389](https://github.com/Saghen/blink.cmp/issues/389)
* Enable experimental Treesitter highlighting on the labels via `completion.menu.draw.treesitter = true`

### BREAKING CHANGES

* nuke the debt ([#389](https://github.com/Saghen/blink.cmp/issues/389)) ([1187172](https://github.com/Saghen/blink.cmp/commit/11871727278381febd05d1ee1a17f98fb2e32b26)), closes [#323](https://github.com/Saghen/blink.cmp/issues/323)

### Features

* add show_on_keyword and show_on_trigger_character trigger options ([69a69dd](https://github.com/Saghen/blink.cmp/commit/69a69dd7c66f2290dea849846402266b2303782c)), closes [#402](https://github.com/Saghen/blink.cmp/issues/402)
* allow completing buffer words with unicode ([#392](https://github.com/Saghen/blink.cmp/issues/392)) ([e1d3e9d](https://github.com/Saghen/blink.cmp/commit/e1d3e9d4a64466b521940b3ccb67c6fd534b0032))
* call execute after accepting, but before applying semantic brackets ([073449a](https://github.com/Saghen/blink.cmp/commit/073449a872d49d0c61cb1cf020232d609b2b3d8c))
* default to empty table for setup ([#412](https://github.com/Saghen/blink.cmp/issues/412)) ([4559ec5](https://github.com/Saghen/blink.cmp/commit/4559ec5cfb91ed8080e2f8df7d4784e12aa27f18))
* error on download failure ([6054da2](https://github.com/Saghen/blink.cmp/commit/6054da23af87117afd1de59bb77df90037e84675))
* nuke the debt ([#389](https://github.com/Saghen/blink.cmp/issues/389)) ([1187172](https://github.com/Saghen/blink.cmp/commit/11871727278381febd05d1ee1a17f98fb2e32b26)), closes [#323](https://github.com/Saghen/blink.cmp/issues/323)
* prebuilt binary retry, disable progress, and docs ([bc67391](https://github.com/Saghen/blink.cmp/commit/bc67391de57ce3e42302b13cccf9dd41207c0860)), closes [#68](https://github.com/Saghen/blink.cmp/issues/68)
* **render:** support `source_id` and `source_name` in menu render ([#400](https://github.com/Saghen/blink.cmp/issues/400)) ([d5f62f9](https://github.com/Saghen/blink.cmp/commit/d5f62f981cde0660944626aaeaab8541c9516346))
* support accepting and drawing by index ([4b1a793](https://github.com/Saghen/blink.cmp/commit/4b1a79305d9acb22171062053a6c942383fefa72)), closes [#382](https://github.com/Saghen/blink.cmp/issues/382)
* support get_bufnrs for the buffer source ([#411](https://github.com/Saghen/blink.cmp/issues/411)) ([4c65dbd](https://github.com/Saghen/blink.cmp/commit/4c65dbde1709bed2cb87483b0ce4eb522098bebc))
* treesitter highlighter ([#404](https://github.com/Saghen/blink.cmp/issues/404)) ([08a0777](https://github.com/Saghen/blink.cmp/commit/08a07776838e205c697a3d05bcf43104a2adacf5))
* use sort_text over label for sorting ([0386120](https://github.com/Saghen/blink.cmp/commit/0386120c3bbe32a6746b73a8e38ec954c58575c9)), closes [#365](https://github.com/Saghen/blink.cmp/issues/365)

### Bug Fixes

* accept grabbing wrong config ([3dcf98d](https://github.com/Saghen/blink.cmp/commit/3dcf98d8a5c1c720d5a3d789ac14a9741dbe70eb))
* allow border to be a table ([52f6387](https://github.com/Saghen/blink.cmp/commit/52f63878c0affef88023cd2a00a103644cb7ccfa)), closes [#398](https://github.com/Saghen/blink.cmp/issues/398)
* auto_insert scheduling and module reference ([1b3cd31](https://github.com/Saghen/blink.cmp/commit/1b3cd31e26066308f97075fee7744cd8694cd75e))
* autocmd called in fast event ([9428983](https://github.com/Saghen/blink.cmp/commit/94289832dc7c148862fdf9326e173df265abe8ad)), closes [#396](https://github.com/Saghen/blink.cmp/issues/396)
* buffer events suppression, auto_insert selection ([96ceb56](https://github.com/Saghen/blink.cmp/commit/96ceb56f7b6e0abeacb01aa2b04abef33121d38b)), closes [#415](https://github.com/Saghen/blink.cmp/issues/415)
* convert additional text edits to utf-8 ([49981f2](https://github.com/Saghen/blink.cmp/commit/49981f2bc8c04967cf868574913f092392a267fe)), closes [#397](https://github.com/Saghen/blink.cmp/issues/397)
* cycling list skipping one item ([07b2ee1](https://github.com/Saghen/blink.cmp/commit/07b2ee14eaae6908f0da44bfa918177d167b12de))
* deduplicate mode changes, dont hide on select mode ([04ff262](https://github.com/Saghen/blink.cmp/commit/04ff262f3590cd9b63dab03e2cecc759d4abdf69)), closes [#393](https://github.com/Saghen/blink.cmp/issues/393)
* default snippet active function not returning ([59add2d](https://github.com/Saghen/blink.cmp/commit/59add2d602d9a13003ed3430232b3689872ea9ac)), closes [#399](https://github.com/Saghen/blink.cmp/issues/399)
* don't set window properties when nil ([cb815af](https://github.com/Saghen/blink.cmp/commit/cb815afca7c32af7feeb3a90d5b450620d4bef2b)), closes [#407](https://github.com/Saghen/blink.cmp/issues/407)
* ensure failed curl doesn't update the version ([933052b](https://github.com/Saghen/blink.cmp/commit/933052b8e9b585c24c493fdc34a66519d4889c1b)), closes [#68](https://github.com/Saghen/blink.cmp/issues/68)
* ensure menu selection index is within bounds ([bb5407d](https://github.com/Saghen/blink.cmp/commit/bb5407d27e93dc71f8572571ab04b3fc02fc8259)), closes [#416](https://github.com/Saghen/blink.cmp/issues/416)
* filter text always being nil ([33f7d8d](https://github.com/Saghen/blink.cmp/commit/33f7d8df8119673b7eca3d7a04ed28b805cae296)), closes [#365](https://github.com/Saghen/blink.cmp/issues/365)
* incorrect context start_col 1 char after beginning of line ([e88da6a](https://github.com/Saghen/blink.cmp/commit/e88da6a123c857ec2da92ff488c3f82cfba718ef)), closes [#405](https://github.com/Saghen/blink.cmp/issues/405)
* invalid configuration and readme after refactor ([56f7cb6](https://github.com/Saghen/blink.cmp/commit/56f7cb679ef9e5c09351bfa67b081c68ad27349f)), closes [#394](https://github.com/Saghen/blink.cmp/issues/394)
* keyword range "full" when covering end of line ([160b687](https://github.com/Saghen/blink.cmp/commit/160b6875095977d49e16c4e33add4b0e6b0c8668)), closes [#268](https://github.com/Saghen/blink.cmp/issues/268)
* misc typing issues ([b94172c](https://github.com/Saghen/blink.cmp/commit/b94172c8b28f6030c0df3f846eec4a129a25c5bb))
* only affect initial show for show_on_keyword and show_on_trigger_character ([ea61b1d](https://github.com/Saghen/blink.cmp/commit/ea61b1dc9ed2c4a092ab1365657bc4220b1b5488)), closes [#402](https://github.com/Saghen/blink.cmp/issues/402)
* signature window highlight ns ([0b9a128](https://github.com/Saghen/blink.cmp/commit/0b9a1282eb4f9e44de66fd689d4e301bb987abf5))
* signature window setup ([cab7576](https://github.com/Saghen/blink.cmp/commit/cab7576350c12de902dc18a85d17f4733f1f9938))
* super-tab preset keymap name ([f569aeb](https://github.com/Saghen/blink.cmp/commit/f569aeb9e684a2b18514077501e98b0f9ef873bd))
* user autocmd called in fast event not being wrapped ([e9baeea](https://github.com/Saghen/blink.cmp/commit/e9baeeac1d05d8cbbbee560380853baeb8b316f3))

### Documentation

* add note about reworked config ([180be7b](https://github.com/Saghen/blink.cmp/commit/180be7ba574033baa30fa8af0db4f59db7353584))

## [0.6.2](https://github.com/Saghen/blink.cmp/compare/v0.6.1...v0.6.2) (2024-11-26)

### Features

* add `cancel` command for use with `auto_insert` ([c58b3a8](https://github.com/Saghen/blink.cmp/commit/c58b3a8ec2cd71b422fbd4b1607e924996dfdebb)), closes [#215](https://github.com/Saghen/blink.cmp/issues/215)
* remove rust from blocked auto brackets filetypes ([8500a62](https://github.com/Saghen/blink.cmp/commit/8500a62e6f07a823b373df91b00c997734b3c664)), closes [#359](https://github.com/Saghen/blink.cmp/issues/359)

### Bug Fixes

* mark all config properties as optional ([e328bde](https://github.com/Saghen/blink.cmp/commit/e328bdedc4d12d01ff5c68bee8ea6ae6f33f42f7)), closes [#370](https://github.com/Saghen/blink.cmp/issues/370)
* path source not handling hidden files correctly ([22c5c0d](https://github.com/Saghen/blink.cmp/commit/22c5c0d2c96d5ab86cd23f8df76f005505138a5d)), closes [#369](https://github.com/Saghen/blink.cmp/issues/369)
* use offset encoding of first client ([0a2abab](https://github.com/Saghen/blink.cmp/commit/0a2ababaa450f50afeb4653c3d40b34344aa80d6)), closes [#380](https://github.com/Saghen/blink.cmp/issues/380)

## [0.6.1](https://github.com/Saghen/blink.cmp/compare/v0.6.0...v0.6.1) (2024-11-24)

### Features

* add prebuilt binaries for android ([#362](https://github.com/Saghen/blink.cmp/issues/362)) ([11a50fe](https://github.com/Saghen/blink.cmp/commit/11a50fe006a4482ab5acb5bcd77efa4fb9f944f8))

## [0.6.0](https://github.com/Saghen/blink.cmp/compare/v0.5.1...v0.6.0) (2024-11-24)

### BREAKING CHANGES

* matched character highlighting, draw rework (#245)
* set default nerd_font_variant to mono

### Features

* add `execute` function for sources ([653b262](https://github.com/Saghen/blink.cmp/commit/653b2629e1dab0c6d0084d90f30a600d601812a1))
* add get_filetype option for snippet source ([#352](https://github.com/Saghen/blink.cmp/issues/352)) ([7c3ad2b](https://github.com/Saghen/blink.cmp/commit/7c3ad2b1fcd0250df69162ad71439cfe547f9608)), closes [#292](https://github.com/Saghen/blink.cmp/issues/292)
* add scrollbar to autocomplete menu ([#259](https://github.com/Saghen/blink.cmp/issues/259)) ([4c2a36c](https://github.com/Saghen/blink.cmp/commit/4c2a36ce8efb2f02d12600b43b3de32898d07433))
* add snippet indicator back to label on render ([6f5ae79](https://github.com/Saghen/blink.cmp/commit/6f5ae79218334e5d1ca783e22847bbc6b4daef16))
* allow disabling keymap by passing an empty table ([e384594](https://github.com/Saghen/blink.cmp/commit/e384594deee2f7be225cb89dbcb72d9b6482fde8))
* avoid taking up space when scrollbar is hidden ([77f037c](https://github.com/Saghen/blink.cmp/commit/77f037cae07358368f3b7548ba39cffceb49349e))
* extract word from completion item for auto-insert preview ([#341](https://github.com/Saghen/blink.cmp/issues/341)) ([285f6f4](https://github.com/Saghen/blink.cmp/commit/285f6f498c8ba3ac0788edb1db2f8d2d3cb20fad))
* matched character highlighting, draw rework ([#245](https://github.com/Saghen/blink.cmp/issues/245)) ([683c47a](https://github.com/Saghen/blink.cmp/commit/683c47ac8c6e538122dc0fe50187b78f8995a549))
* option to disable treesitter highlighting ([1c14f8e](https://github.com/Saghen/blink.cmp/commit/1c14f8e8817015634c593eb3832a73e4993c561e))
* position documentation based on desired size, not max size ([973f06a](https://github.com/Saghen/blink.cmp/commit/973f06a164835b74247f46b3c5b2ae895a1acb1b))
* set default nerd_font_variant to mono ([d3e1c92](https://github.com/Saghen/blink.cmp/commit/d3e1c92e68b74f3d05f6ab7dfff2af8f83769149))
* support editRange, use textEditText when editRange is defined ([db3d1ad](https://github.com/Saghen/blink.cmp/commit/db3d1ad8d6420ce29d548991468cc0107fe9d04b)), closes [#310](https://github.com/Saghen/blink.cmp/issues/310)
* temporarily disable markdown combining ([24b4d35](https://github.com/Saghen/blink.cmp/commit/24b4d350b469595ff39ce48a45ee12b59578aae6))
* use filter_text when available ([12b4f11](https://github.com/Saghen/blink.cmp/commit/12b4f116648d87551a07def740a0375446105bbc))
* validate provider names in enabled_providers ([e9c9b41](https://github.com/Saghen/blink.cmp/commit/e9c9b41ea0f8ae36b7c19c970bf313f1ca93bd1b))

### Bug Fixes

* add ctx.icon_gap in kind_icon component ([ccf02f5](https://github.com/Saghen/blink.cmp/commit/ccf02f5e39e3ed7b4e65dbe667a3329313540eba))
* applying preview text_edit ([#296](https://github.com/Saghen/blink.cmp/issues/296)) ([8372a6b](https://github.com/Saghen/blink.cmp/commit/8372a6bfce9499f3bb8a91a23db8fe1d83f2d625))
* check if source is in `enabled_providers` before calling source:enabled ([#266](https://github.com/Saghen/blink.cmp/issues/266)) ([338d2a6](https://github.com/Saghen/blink.cmp/commit/338d2a6e81b9e0f9e66b691c36c9959a2705085a))
* clear last_char on trigger hide ([1ce30c9](https://github.com/Saghen/blink.cmp/commit/1ce30c9d1aa539f05e99b9ecea0dcc35d4cc33fe)), closes [#228](https://github.com/Saghen/blink.cmp/issues/228)
* completion label details containing newline characters ([#265](https://github.com/Saghen/blink.cmp/issues/265)) ([1628800](https://github.com/Saghen/blink.cmp/commit/1628800e1747ecc767368cab45916177c723da82))
* consider the border when calculating the position of the autocom… ([#325](https://github.com/Saghen/blink.cmp/issues/325)) ([41178d3](https://github.com/Saghen/blink.cmp/commit/41178d39670ce8db5e93a0028a7f23729559a326))
* consider the border when calculating the width of the documentat… ([#326](https://github.com/Saghen/blink.cmp/issues/326)) ([130eb51](https://github.com/Saghen/blink.cmp/commit/130eb512e2849c021d73bd269b77cc3b0ecf8b74))
* convert to utf-8 encoding on text edits ([2e37993](https://github.com/Saghen/blink.cmp/commit/2e379931090f3737b844598a18382241197aaa2a)), closes [#188](https://github.com/Saghen/blink.cmp/issues/188) [#200](https://github.com/Saghen/blink.cmp/issues/200)
* default highlight groups ([#317](https://github.com/Saghen/blink.cmp/issues/317)) ([69a987b](https://github.com/Saghen/blink.cmp/commit/69a987b96cf754a12b6d7dafce1d2d49ade591f2))
* default to item when assigning defaults, only use known defaults ([fb9f374](https://github.com/Saghen/blink.cmp/commit/fb9f3744cbc4c8b0c6792ed1c072009864a1bd6d)), closes [#151](https://github.com/Saghen/blink.cmp/issues/151)
* documentation misplacement due to screenpos returning 0,0 ([cb0baa4](https://github.com/Saghen/blink.cmp/commit/cb0baa4403fe5cf6d5dc3af483176780e44ba071))
* download mechanism works with GIT_DIR and GIT_WORK_TREE set ([#275](https://github.com/Saghen/blink.cmp/issues/275)) ([8c9930c](https://github.com/Saghen/blink.cmp/commit/8c9930c94e17ca0ab9956986b175cd91f4ac3a59))
* drop unnecessary filetype configuration ([bec27d9](https://github.com/Saghen/blink.cmp/commit/bec27d9196fe3c0020b56e49533a8f08cc8ea45f)), closes [#295](https://github.com/Saghen/blink.cmp/issues/295)
* drop vim print ([c3447cc](https://github.com/Saghen/blink.cmp/commit/c3447cc2bd4afec7050230b49a3e889c43084400))
* get the cursor position relative to the window instead of the sc… ([#327](https://github.com/Saghen/blink.cmp/issues/327)) ([5479abf](https://github.com/Saghen/blink.cmp/commit/5479abfbfb47bf4d23220a6e5a3eb11f23e57214))
* **ghost-text:** flickering using autocmds ([#255](https://github.com/Saghen/blink.cmp/issues/255)) ([a94bbaf](https://github.com/Saghen/blink.cmp/commit/a94bbaf9f2c6329f4593233f069b3dea21b4cedc))
* handle gap for empty text ([#301](https://github.com/Saghen/blink.cmp/issues/301)) ([371ad28](https://github.com/Saghen/blink.cmp/commit/371ad288544423531121c1abf0d519dda791e9f1))
* handle not being in a git repository, fix error on flakes ([#281](https://github.com/Saghen/blink.cmp/issues/281)) ([d2a216d](https://github.com/Saghen/blink.cmp/commit/d2a216de72a6b3a741c214b66e70897ff6f16dc2))
* ignore empty doc lines and detail lines ([aeaa2e7](https://github.com/Saghen/blink.cmp/commit/aeaa2e78dad7885e99b5a00a70b9c57c5a5302aa)), closes [#247](https://github.com/Saghen/blink.cmp/issues/247)
* join newlines in `label_description` ([#333](https://github.com/Saghen/blink.cmp/issues/333)) ([8ba2069](https://github.com/Saghen/blink.cmp/commit/8ba2069a57cf6580dea6a50bf71e5b3b2924b284))
* make ghost-text extmark with pcall ([#287](https://github.com/Saghen/blink.cmp/issues/287)) ([a2f6cfb](https://github.com/Saghen/blink.cmp/commit/a2f6cfb2902e1410f5cdbf386b9af337754f1a07))
* offset encoding conversion on nvim 0.11.0 ([#308](https://github.com/Saghen/blink.cmp/issues/308)) ([9822c6b](https://github.com/Saghen/blink.cmp/commit/9822c6b40ad91a14e2c75696db30999ae5cf1fc5)), closes [#307](https://github.com/Saghen/blink.cmp/issues/307)
* offset encoding for text edits ([c2a56e4](https://github.com/Saghen/blink.cmp/commit/c2a56e473ff5952211f7c890de0b831e8df3976d))
* only undo if not snippet ([f4dcebf](https://github.com/Saghen/blink.cmp/commit/f4dcebfd720810b14eb2ad62102028c104bf2205)), closes [#244](https://github.com/Saghen/blink.cmp/issues/244)
* override typing and module ([f1647f7](https://github.com/Saghen/blink.cmp/commit/f1647f7fd97ac7129e1cb8a1ed242ae326f25d6e))
* padded window ([#315](https://github.com/Saghen/blink.cmp/issues/315)) ([7a37c64](https://github.com/Saghen/blink.cmp/commit/7a37c643412f19b04a03ed4c71e94da175efcfb8))
* prevent index out of bounds in get_code_block_range ([#271](https://github.com/Saghen/blink.cmp/issues/271)) ([e6c735b](https://github.com/Saghen/blink.cmp/commit/e6c735be455c90df4aa7c11cfe7542f111234de6))
* remove offset from label detail highlight ([5262586](https://github.com/Saghen/blink.cmp/commit/52625866f5b9a9358313308276dcf110cf1a42ea))
* reset documentation scroll on new item ([cd3aa32](https://github.com/Saghen/blink.cmp/commit/cd3aa32276308d0c1bddf7a14cd13a8776eb5575)), closes [#239](https://github.com/Saghen/blink.cmp/issues/239)
* scrollbar gutter not updating on window resize ([c8cf209](https://github.com/Saghen/blink.cmp/commit/c8cf209dc843c5a42945bb95a4b8598bcab8c6f8))
* **scrollbar:** use cursorline to determine thumb position ([#267](https://github.com/Saghen/blink.cmp/issues/267)) ([28fcf95](https://github.com/Saghen/blink.cmp/commit/28fcf952d14a022cd64f89ff32b3442c6101b873))
* signature help now highlights the right parameter ([#297](https://github.com/Saghen/blink.cmp/issues/297)) ([3fe4c75](https://github.com/Saghen/blink.cmp/commit/3fe4c75c69f208462c4e8957005f6ccb72b1da25))
* **snippets:** fix nullpointer exception ([#355](https://github.com/Saghen/blink.cmp/issues/355)) ([3ac471b](https://github.com/Saghen/blink.cmp/commit/3ac471bbfe614adb77fc8179dd4adaa0d1576542))
* tailwind colors ([#306](https://github.com/Saghen/blink.cmp/issues/306)) ([8e3af0e](https://github.com/Saghen/blink.cmp/commit/8e3af0ec0079b599fb57f97653b2f20f98e2a5bb))
* **types:** allow resolving empty response from blink.cmd.Source ([#254](https://github.com/Saghen/blink.cmp/issues/254)) ([46a5f0b](https://github.com/Saghen/blink.cmp/commit/46a5f0b9fd8e6753d118853d384ae85bfdb70c30))
* use pmenu scrollbar highlights ([5632376](https://github.com/Saghen/blink.cmp/commit/5632376d4f51d777013d5f48414a15f02be854af))

## [0.5.1](https://github.com/Saghen/blink.cmp/compare/v0.5.0...v0.5.1) (2024-11-03)

### BREAKING CHANGES

* set max_width to 80 for documentation

### Features

* 'enter' keymap ([4ec5cea](https://github.com/Saghen/blink.cmp/commit/4ec5cea4858eee31919cc2a5bc1850846073c5ec))
* add label details to all draw functions ([f9c58ab](https://github.com/Saghen/blink.cmp/commit/f9c58ab26a427883965394959276fd347574b11e)), closes [#97](https://github.com/Saghen/blink.cmp/issues/97)
* add winblend option for windows ([#237](https://github.com/Saghen/blink.cmp/issues/237)) ([ca94ee0](https://github.com/Saghen/blink.cmp/commit/ca94ee0b1ec848bac6426811f12f6da39e48d02a))
* align completion window ([#235](https://github.com/Saghen/blink.cmp/issues/235)) ([0c13fbd](https://github.com/Saghen/blink.cmp/commit/0c13fbd3d7bed1d4bab08d3831c95ee3dfb7277f)), closes [#221](https://github.com/Saghen/blink.cmp/issues/221)
* allow merging of keymap preset with custom keymap ([#233](https://github.com/Saghen/blink.cmp/issues/233)) ([6b46164](https://github.com/Saghen/blink.cmp/commit/6b46164eac2feb6dd49e6e8c434cb276f50c8132))
* better extraction of detail from doc ([b0815e4](https://github.com/Saghen/blink.cmp/commit/b0815e461623d9a9ea06fb632167ca25656abcf5))
* only offset window when using preset draw ([75cadbc](https://github.com/Saghen/blink.cmp/commit/75cadbcd2657ed01326ca2b0e5e4d78a77127ca3))
* rework window positioning ([a67adaf](https://github.com/Saghen/blink.cmp/commit/a67adaf623f9c6e1803a693044608b73e02e8da3)), closes [#45](https://github.com/Saghen/blink.cmp/issues/45) [#194](https://github.com/Saghen/blink.cmp/issues/194)
* set max_width to 80 for documentation ([dc1de2b](https://github.com/Saghen/blink.cmp/commit/dc1de2bf962c67e8ba8647710817bbce04f92bdb))
* TailwindCSS highlight support ([#143](https://github.com/Saghen/blink.cmp/issues/143)) ([b2bbef5](https://github.com/Saghen/blink.cmp/commit/b2bbef52f24799f0e79a3adf6038366b26e2451b))

### Bug Fixes

* add "enter" keymap to types ([3ca68ef](https://github.com/Saghen/blink.cmp/commit/3ca68ef008e383a28c760de2d5ee65b35efbb5c5))
* allow to be lazy loaded on InsertEnter ([#243](https://github.com/Saghen/blink.cmp/issues/243)) ([9d50661](https://github.com/Saghen/blink.cmp/commit/9d5066134b339c5e4aa6cec3daa086d3b0671892))
* alpine linux detection ([a078c87](https://github.com/Saghen/blink.cmp/commit/a078c877ac17a912a51aba9d9e0068a0f1ed509b))
* check LSP methods before requesting ([193423c](https://github.com/Saghen/blink.cmp/commit/193423ca584e4e1a9639d6c480a6b952db566c21)), closes [#220](https://github.com/Saghen/blink.cmp/issues/220)
* documentation width ([9bdd828](https://github.com/Saghen/blink.cmp/commit/9bdd828e474e69badb64a305179930cf66acf649))
* **documentation:** better docs ([#234](https://github.com/Saghen/blink.cmp/issues/234)) ([a253b35](https://github.com/Saghen/blink.cmp/commit/a253b356092b8f64ac66200c249afe5978c3fc39))
* enable show_in_snippet by default ([76d11a6](https://github.com/Saghen/blink.cmp/commit/76d11a617075dc53e89e1c9b9ce5c62435abdfba))
* ensure treesitter does not run on windows ([2ac2f43](https://github.com/Saghen/blink.cmp/commit/2ac2f43513cdf63313192271427cc55608f0bedb)), closes [#193](https://github.com/Saghen/blink.cmp/issues/193)
* lazily call fuzzy access ([aeb6195](https://github.com/Saghen/blink.cmp/commit/aeb6195ba870c61e4e0f2d4e8ef1bcc80464af9b))
* make all of source provider config optional ([055b943](https://github.com/Saghen/blink.cmp/commit/055b9435358f68ae26de75d9294749bd69c22ccc))
* only check enabled fallback sources ([#232](https://github.com/Saghen/blink.cmp/issues/232)) ([ecb3520](https://github.com/Saghen/blink.cmp/commit/ecb3520c899eee9dbe738620f3c327b8089fe1f8))
* window direction and autocomplete closing on position update ([4b3fd8f](https://github.com/Saghen/blink.cmp/commit/4b3fd8f5ce6ece4f84d6c6ddfd0a42f43b889574)), closes [#240](https://github.com/Saghen/blink.cmp/issues/240)

## [0.5.0](https://github.com/Saghen/blink.cmp/compare/v0.4.1...v0.5.0) (2024-10-30)

> [!IMPORTANT]  
> The **keymap** configuration has been reworked, please see the README for the new schema

You may now use `nvim-cmp` sources within `blink.cmp` using @stefanboca's compatibility layer: https://github.com/Saghen/blink.compat

### BREAKING CHANGES

* rework keymap config

### Features

* `enabled` function for sources ([c104663](https://github.com/Saghen/blink.cmp/commit/c104663e92c15dd59ee3b299249361cd095206f4)), closes [#208](https://github.com/Saghen/blink.cmp/issues/208)
* accept error handling, expose autocomplete.select ([9cd1236](https://github.com/Saghen/blink.cmp/commit/9cd123657fce6e563a7d24b438f61b012ca1559f))
* cache resolve tasks ([83a8303](https://github.com/Saghen/blink.cmp/commit/83a8303e2744d01249f465f219f0dc5a41104a9e))
* glibc 2.17 and musl prebuilt binaries ([c593835](https://github.com/Saghen/blink.cmp/commit/c593835fe1b0297dfbcabe46edcd1edb9d317b94)), closes [#160](https://github.com/Saghen/blink.cmp/issues/160)
* ignore _*.lua files ([f6eccaf](https://github.com/Saghen/blink.cmp/commit/f6eccaf3f2ef8939ea661ee8384e299a9428999c))
* lsp capabilities ([e0e08cb](https://github.com/Saghen/blink.cmp/commit/e0e08cbfea667ff21b9e6e5acb0389ddd6d2de41))
* output preview with ghost text, including for snippets ([#186](https://github.com/Saghen/blink.cmp/issues/186)) ([6d25187](https://github.com/Saghen/blink.cmp/commit/6d2518745db83da0b15f60e22c15c205fb1ed56f))
* **perf:** call score_offset func once per source ([bd90e00](https://github.com/Saghen/blink.cmp/commit/bd90e007f33c60a3a11bb99ff2e8bfd897fe27b3))
* prefetch resolve on select ([52ec2c9](https://github.com/Saghen/blink.cmp/commit/52ec2c985cb0ef9459b73bb8b08801f35f092f6d))
* resolve item before accept ([3927128](https://github.com/Saghen/blink.cmp/commit/3927128e712806c22c20487ef0a1ed885bfec292))
* rework keymap config ([3fd92f0](https://github.com/Saghen/blink.cmp/commit/3fd92f0bbceb31a3cd32b1d7a9d2a62071c85d91))
* show completion window after accept if on trigger character ([28e0b5a](https://github.com/Saghen/blink.cmp/commit/28e0b5a873c6f4e687260384595a05c55a888ccf)), closes [#198](https://github.com/Saghen/blink.cmp/issues/198)
* support disabling accept on trigger character, block parenthesis ([125d4f1](https://github.com/Saghen/blink.cmp/commit/125d4f1288b3b309d219848559adfca3cc61f8b5)), closes [#212](https://github.com/Saghen/blink.cmp/issues/212)
* switch default keymap to select_and_accept ([f0f2672](https://github.com/Saghen/blink.cmp/commit/f0f26728c3e5c65cf2d27a1b24e4e3fbd26773fb))
* use treesitter for signature help hl ([0271d79](https://github.com/Saghen/blink.cmp/commit/0271d7957324df68bd352fc7aef60606c96c88ca))

### Bug Fixes

* add back cursor move after accept, but use current line ([ceeeb53](https://github.com/Saghen/blink.cmp/commit/ceeeb538b091c43aa6fb6fd6020531a37cef2191))
* always return item in resolve ([6f0fc86](https://github.com/Saghen/blink.cmp/commit/6f0fc86f8fbb94ae23770c01dc2e3cf9e1886e99)), closes [#211](https://github.com/Saghen/blink.cmp/issues/211)
* documentation auto show no longer working ([#202](https://github.com/Saghen/blink.cmp/issues/202)) ([6290abd](https://github.com/Saghen/blink.cmp/commit/6290abd24b14723ba4827c28367a805bcc4773de))
* dont move cursor after accepting ([cab91c5](https://github.com/Saghen/blink.cmp/commit/cab91c5f56eb15394d4cabddcd62eee6963129ec))
* fallback show_documentation when window open ([bc311b7](https://github.com/Saghen/blink.cmp/commit/bc311b756ca89652bfb18b07a99ff52f424d63a2))
* handle failed lsp resolve request gracefully ([4c40bf2](https://github.com/Saghen/blink.cmp/commit/4c40bf25f2371d6b3df6f130e154ebac0b9c3422))
* ignore nil item for resolve prefetching ([b7d1233](https://github.com/Saghen/blink.cmp/commit/b7d1233d826a0406538955b4ef2448dc0e72c536)), closes [#209](https://github.com/Saghen/blink.cmp/issues/209)
* invalid insertTextMode capabilities ([4de7b7e](https://github.com/Saghen/blink.cmp/commit/4de7b7e64100cfdbfc564c475a1713ba2498ba25))
* prevent treesitter from running on windows ([9b9be31](https://github.com/Saghen/blink.cmp/commit/9b9be318773dcce04f5017574fbe5ed638429852))
* schedule non-expr fallback keymaps ([#196](https://github.com/Saghen/blink.cmp/issues/196)) ([1a55fd1](https://github.com/Saghen/blink.cmp/commit/1a55fd1e03193e10cb8bc866cc2bc47c9473061c))
* sending erroneous fields to LSP on resolve ([e82c1b7](https://github.com/Saghen/blink.cmp/commit/e82c1b73607c4905582028e81bc40b10ce9eb8ea))
* set default keymap to use accept ([7d265b4](https://github.com/Saghen/blink.cmp/commit/7d265b4a19f2c198eda06baf031cb0e41cc3095c))
* snippet reload function ([407f2d5](https://github.com/Saghen/blink.cmp/commit/407f2d526fd07b651a8a7330df2c4fd05b32a014))
* snippet resolve ([5d9fa1c](https://github.com/Saghen/blink.cmp/commit/5d9fa1c36cc9e43a9d7cd65ddcc417128a9d41c3))

## [0.4.1](https://github.com/Saghen/blink.cmp/compare/v0.4.0...v0.4.1) (2024-10-24)

### Bug Fixes

* check semantic token type ([0b493ff](https://github.com/Saghen/blink.cmp/commit/0b493ff3ce7fd8d318e7e1024fbadfe2ec3a624a))
* exclude prefix including one char ([70438ac](https://github.com/Saghen/blink.cmp/commit/70438ac5016d3ab609f422d1ef084870cb9ceb29))

## [0.4.0](https://github.com/Saghen/blink.cmp/compare/v0.3.1...v0.4.0) (2024-10-24)

> [!IMPORTANT]  
> The sources configuration has been reworked, please see the README for the new schema

### BREAKING CHANGES

* rework sources config structure and available options
* rework sources system and configuration

### Features

* add extra space to ... on normal nerd font ([9b9647b](https://github.com/Saghen/blink.cmp/commit/9b9647bc23f52270ce43e579dda9b9eb5d00b7b8))
* add nix build-plugin command, update devShell to not require ([32069be](https://github.com/Saghen/blink.cmp/commit/32069be108dda4cf2b0a7316a0be366398187003))
* auto_show on autocomplete window ([#98](https://github.com/Saghen/blink.cmp/issues/98)) ([82e03b1](https://github.com/Saghen/blink.cmp/commit/82e03b1207b14845d8f29041e2f244693708425b))
* **config:** add ignored filetypes option ([#108](https://github.com/Saghen/blink.cmp/issues/108)) ([b56a2b1](https://github.com/Saghen/blink.cmp/commit/b56a2b18804a9e4cce6450b886c33fb6b0a58e39))
* custom documentation highlighting ([90d6394](https://github.com/Saghen/blink.cmp/commit/90d63948368982800ce886e93fc9c7d1c36cf74c)), closes [#113](https://github.com/Saghen/blink.cmp/issues/113)
* default to not showing in snippet ([49b033a](https://github.com/Saghen/blink.cmp/commit/49b033a11830652790603fe9b2a7e6275e626730)), closes [#131](https://github.com/Saghen/blink.cmp/issues/131)
* expose reload function for sources ([ff1f5fa](https://github.com/Saghen/blink.cmp/commit/ff1f5fa525312676f1aaba9b601bd0e13c52644b)), closes [#28](https://github.com/Saghen/blink.cmp/issues/28)
* expose typo resistance, update frizbee ([63b7b22](https://github.com/Saghen/blink.cmp/commit/63b7b2219f4595973225a13e6e664fc836ee305c))
* **fuzzy:** lazy get lua properties ([5cc63f0](https://github.com/Saghen/blink.cmp/commit/5cc63f0f298ad31cab37d7b2a478e61a3601a768))
* ignore empty fallback_for table ([9c9e0cc](https://github.com/Saghen/blink.cmp/commit/9c9e0cc78b0933c66916eaccc6a974608d2426de)), closes [#122](https://github.com/Saghen/blink.cmp/issues/122)
* ignore some characters at prefix of keyword ([569156f](https://github.com/Saghen/blink.cmp/commit/569156f432e67a4bd4dccee4fb9beafbf15a1d30)), closes [#135](https://github.com/Saghen/blink.cmp/issues/135)
* mark buffer completion items as plain text ([0f5f484](https://github.com/Saghen/blink.cmp/commit/0f5f484583b19484599b9dfb524180902d10e5b3)), closes [#148](https://github.com/Saghen/blink.cmp/issues/148)
* more robust preview for auto_insert mode ([6e15864](https://github.com/Saghen/blink.cmp/commit/6e158647bbc0628fe46c0175acf32d954c0c172f)), closes [#117](https://github.com/Saghen/blink.cmp/issues/117)
* notify user on json parsing error for snippets ([c5146a5](https://github.com/Saghen/blink.cmp/commit/c5146a5c23db48824fc7720f1265f3e75fc1c634)), closes [#132](https://github.com/Saghen/blink.cmp/issues/132)
* place cursor at first tab stop on snippet preview ([d3e8701](https://github.com/Saghen/blink.cmp/commit/d3e87015e891022a8fe36f43c60806c21f231cea))
* re-enable typo resistance by default ([b35a559](https://github.com/Saghen/blink.cmp/commit/b35a559abea64a1b77abf69e8252ab5cd063868a))
* reduce build-plugin command to minimal dependencies, add command to docs ([cfaf9fc](https://github.com/Saghen/blink.cmp/commit/cfaf9fc89a4b0ad36bba7a2605ae9b2f15efbf52))
* remove snippet deduplication ([e296d8f](https://github.com/Saghen/blink.cmp/commit/e296d8ffcea78c400210d09c669359af89802618)), closes [#146](https://github.com/Saghen/blink.cmp/issues/146)
* rework sources config structure and available options ([e3a811b](https://github.com/Saghen/blink.cmp/commit/e3a811bc9bc9cf55de8bd7a7bcee84236e015dc2)), closes [#144](https://github.com/Saghen/blink.cmp/issues/144)
* rework sources system and configuration ([7fea65c](https://github.com/Saghen/blink.cmp/commit/7fea65c4e4c83d3b194a4d9e4d813204fd9f0ded)), closes [#144](https://github.com/Saghen/blink.cmp/issues/144)
* select_and_accept keymap ([6394508](https://github.com/Saghen/blink.cmp/commit/6394508b0c3f1f1f95e02c8057ccfc4b746dbd75)), closes [#118](https://github.com/Saghen/blink.cmp/issues/118)
* support detail only in doc window ([#147](https://github.com/Saghen/blink.cmp/issues/147)) ([57abdb8](https://github.com/Saghen/blink.cmp/commit/57abdb838cfcc624a87dba2b10f665c30e604b4e))
* support LSP item defaults ([ffc4282](https://github.com/Saghen/blink.cmp/commit/ffc428208f292fa00cb7cced09d35de6e815ab55))
* support LSPs with only full semantic tokens and cleanup ([0626cb5](https://github.com/Saghen/blink.cmp/commit/0626cb5446fd8d4ccfae53a93b648534ea1c7bf3))
* support using suffix for fuzzy matching ([815f4df](https://github.com/Saghen/blink.cmp/commit/815f4dffa58d89d95c6f6e12133b0c1103fa0bdd)), closes [#88](https://github.com/Saghen/blink.cmp/issues/88)
* switch to mlua ([#105](https://github.com/Saghen/blink.cmp/issues/105)) ([873680d](https://github.com/Saghen/blink.cmp/commit/873680d16459d6747609804b08612f6a11f04591))
* use textEditText as fallback for textEdit ([abcb2a0](https://github.com/Saghen/blink.cmp/commit/abcb2a0dab207e03d382acf62074f639a3572e20))
* **windows:** add support for individual border character highlights ([#175](https://github.com/Saghen/blink.cmp/issues/175)) ([3c1a502](https://github.com/Saghen/blink.cmp/commit/3c1a5020ab9a993e8bc8c5c05d29588747f00b78))

### Bug Fixes

* add back undo text edit for accept ([f62046a](https://github.com/Saghen/blink.cmp/commit/f62046a775605f597f2b370672d05ee0c9123142))
* add missing select_and_accept keymap to config ([d2140dc](https://github.com/Saghen/blink.cmp/commit/d2140dc7615991ea88fa1fd75dd4fccb53a73e25))
* always hide window on accept ([7f5a3d9](https://github.com/Saghen/blink.cmp/commit/7f5a3d9a820125e7da0a1816efaddb84d47a7f18))
* auto insert breaking on single line text edit ([78ac56e](https://github.com/Saghen/blink.cmp/commit/78ac56e96144ed7475bb6d11981d3c8154bfd366)), closes [#169](https://github.com/Saghen/blink.cmp/issues/169)
* check if item contains brackets before deferring to semantic token ([e5f543d](https://github.com/Saghen/blink.cmp/commit/e5f543da2a0ce91c8720b67f0ea6cfa941dc26d6))
* **config:** set correct type def for blink.cmp.WindowBorderChar ([516190b](https://github.com/Saghen/blink.cmp/commit/516190bcdafa387d417cfb235cbcd7385e902089))
* don't show completions when trigger context is nil ([5b39d83](https://github.com/Saghen/blink.cmp/commit/5b39d83ac4fed46c57d8db987ea56cb1c0e68b0e))
* drop prints ([89259f9](https://github.com/Saghen/blink.cmp/commit/89259f936e413e0a324b2ea369eb8ccefc05a14f)), closes [#179](https://github.com/Saghen/blink.cmp/issues/179)
* drop prints ([67fa41f](https://github.com/Saghen/blink.cmp/commit/67fa41f0f0501beb64d4acc8678f8788331a470e))
* frizbee not matching on capital letters ([722b41b](https://github.com/Saghen/blink.cmp/commit/722b41b0a7028581004888623f3f79c1d9eab8b8)), closes [#162](https://github.com/Saghen/blink.cmp/issues/162) [#173](https://github.com/Saghen/blink.cmp/issues/173)
* fuzzy get query returning extra characters ([b2380a0](https://github.com/Saghen/blink.cmp/commit/b2380a0301e4385e4964cd57e790d6ce169b2b71)), closes [#170](https://github.com/Saghen/blink.cmp/issues/170) [#172](https://github.com/Saghen/blink.cmp/issues/172) [#176](https://github.com/Saghen/blink.cmp/issues/176)
* fuzzy panic on too many items ([1e6dcbf](https://github.com/Saghen/blink.cmp/commit/1e6dcbffbe224fa10ef9fab490ad07dbd9dd19b0))
* handle treesitter get_parser failure ([fe68c28](https://github.com/Saghen/blink.cmp/commit/fe68c288268f01d1e3b7e692abac2e1fb2093d78)), closes [#171](https://github.com/Saghen/blink.cmp/issues/171)
* item defaults not being applied ([42f8efb](https://github.com/Saghen/blink.cmp/commit/42f8efb43bed968050fcb8feb5fad4b6b27a9b05)), closes [#158](https://github.com/Saghen/blink.cmp/issues/158)
* missing access function ([d11f271](https://github.com/Saghen/blink.cmp/commit/d11f271ddd980e05545627093924e8359c5416b3))
* only show autocomplete window on select if auto_show is disabled ([fa64556](https://github.com/Saghen/blink.cmp/commit/fa6455635b8f12504e2e892fd8ce8926e679cf68))
* re-enable memory check for now ([6b24f48](https://github.com/Saghen/blink.cmp/commit/6b24f484d56eeb9b48cb4ce6b58481cdfc50a3bd))
* remove debug prints ([9846c2d](https://github.com/Saghen/blink.cmp/commit/9846c2d2bfdeaa3088c9c0143030524402fffdf9))
* select always triggering when auto_show enabled ([db635f2](https://github.com/Saghen/blink.cmp/commit/db635f201f5ac5f48e7e33cc268f23e7646fd946))
* select_and_accept not working with auto_insert ([65eb336](https://github.com/Saghen/blink.cmp/commit/65eb336f6c33964becacfbfc850f18d6e3cd5581)), closes [#118](https://github.com/Saghen/blink.cmp/issues/118)
* signature window no longer overlaps cursor ([#149](https://github.com/Saghen/blink.cmp/issues/149)) ([7d6b50b](https://github.com/Saghen/blink.cmp/commit/7d6b50b140eadb51d1bf59b93a02293333a59519))
* single char non-matching keyword ([3cb084c](https://github.com/Saghen/blink.cmp/commit/3cb084cc4e3cc989895d0eabf0ccc690c15d19ed)), closes [#141](https://github.com/Saghen/blink.cmp/issues/141)
* skip treesitter hl on nil lang ([cb9397c](https://github.com/Saghen/blink.cmp/commit/cb9397c89104ab09d85ba5ce1b40852635f9b142))
* temporary workaround for insertReplaceEdit ([c218faf](https://github.com/Saghen/blink.cmp/commit/c218fafbf275725532f3cf2eaebdf863b958d48e)), closes [#178](https://github.com/Saghen/blink.cmp/issues/178)
* typo in signature.win ([#125](https://github.com/Saghen/blink.cmp/issues/125)) ([69ad25f](https://github.com/Saghen/blink.cmp/commit/69ad25f38e1eb833b7aa5a0efb2d6c485e191149))
* use treesitter.language.get_lang when choosing parser ([213fd94](https://github.com/Saghen/blink.cmp/commit/213fd94de2ab83ff409e1fd240625959bf61624e)), closes [#133](https://github.com/Saghen/blink.cmp/issues/133)
* window positioning with folds ([819b978](https://github.com/Saghen/blink.cmp/commit/819b978328b244fc124cfcd74661b2a7f4259f4f)), closes [#95](https://github.com/Saghen/blink.cmp/issues/95)

## [0.3.1](https://github.com/Saghen/blink.cmp/compare/v0.3.0...v0.3.1) (2024-10-14)

### Bug Fixes

* **ci:** use correct file ext for windows ([af68874](https://github.com/Saghen/blink.cmp/commit/af68874f1b2e628e0c72ec27f5225d0c6b2d6820))

## [0.3.0](https://github.com/Saghen/blink.cmp/compare/v0.2.1...v0.3.0) (2024-10-14)

### BREAKING CHANGES

* implement auto-insert option (#65)
* autocompletion window components alignment (#51)
* disable auto_show documentation by default, use <C-space> to toggle

### Features

* add back min_width to autocomplete ([9a008c9](https://github.com/Saghen/blink.cmp/commit/9a008c942f180a23671f598ed9680770b254a599))
* add basic event trigger API ([#31](https://github.com/Saghen/blink.cmp/issues/31)) ([127f518](https://github.com/Saghen/blink.cmp/commit/127f51827cc038aab402abc6bacf9862dd2d72ad))
* add detail to documentation window ([#33](https://github.com/Saghen/blink.cmp/issues/33)) ([588e4d4](https://github.com/Saghen/blink.cmp/commit/588e4d4a7e42bae0e26c82ebc1ea3c68fa4e7cf0))
* add health.lua and basic healthchecks ([#101](https://github.com/Saghen/blink.cmp/issues/101)) ([a12617d](https://github.com/Saghen/blink.cmp/commit/a12617d1eb69484d2656ccc40c40e8254b1ea3ec))
* add minimal render style ([#85](https://github.com/Saghen/blink.cmp/issues/85)) ([b4bbad1](https://github.com/Saghen/blink.cmp/commit/b4bbad181b0e1b9cdf1025b790cf720d707a8c26))
* added a preselect option to the cmp menu ([#24](https://github.com/Saghen/blink.cmp/issues/24)) ([1749e32](https://github.com/Saghen/blink.cmp/commit/1749e32c524dc1815fe4abbad0b33439316c4596))
* apply keymap on InsertEnter ([340370d](https://github.com/Saghen/blink.cmp/commit/340370d526996b99ff75c1858294f15502af0179)), closes [#37](https://github.com/Saghen/blink.cmp/issues/37)
* **ci:** support windows pre-built binaries ([#100](https://github.com/Saghen/blink.cmp/issues/100)) ([b378d50](https://github.com/Saghen/blink.cmp/commit/b378d5022743e56dc450ab1b6a75ab03de36f86b))
* disable auto_show documentation by default, use <C-space> to toggle ([84361bd](https://github.com/Saghen/blink.cmp/commit/84361bdbd9e9ab2a7c06b0f458c2829cef46348d))
* don't search forward when guessing text edit ([a7e1acc](https://github.com/Saghen/blink.cmp/commit/a7e1acc1ed9b0ad004af124bcb6c7d71a7eb5378)), closes [#58](https://github.com/Saghen/blink.cmp/issues/58)
* drop source groups in favor of fallback_for ([#83](https://github.com/Saghen/blink.cmp/issues/83)) ([1f0c0f3](https://github.com/Saghen/blink.cmp/commit/1f0c0f349488f5138757abec2d327ac6c143a4f0))
* expose source provider config to sources ([deba523](https://github.com/Saghen/blink.cmp/commit/deba523406f45eb0a227c33d57a8d75a79abb4cf))
* ignore repeated call at cursor position in trigger ([4883420](https://github.com/Saghen/blink.cmp/commit/48834207c143f5e84d7a71cd250b2049ec0a6d8c))
* implement auto-insert option ([#65](https://github.com/Saghen/blink.cmp/issues/65)) ([1df7d33](https://github.com/Saghen/blink.cmp/commit/1df7d33e930c042dc91287a02a97e1ccf8a92d5d))
* make fuzzy secondary min_score more lenient ([b330b61](https://github.com/Saghen/blink.cmp/commit/b330b61ffac753be3f1257eda92e1596c0ab3174))
* stylize markdown in documentation window ([05229dd](https://github.com/Saghen/blink.cmp/commit/05229ddc2fd1695c979e2807aa96842978dd4779))
* use faster shallow_copy for context ([98575f0](https://github.com/Saghen/blink.cmp/commit/98575f054db18bc763100b8d14a9eae0417209d5))

### Bug Fixes

* accept replacing first char in line ([655d2ee](https://github.com/Saghen/blink.cmp/commit/655d2ee2673950451a491294fd3ce7e17cfb0a24)), closes [#38](https://github.com/Saghen/blink.cmp/issues/38)
* add union to utils ([88f71b1](https://github.com/Saghen/blink.cmp/commit/88f71b16ecd650775516bd2b30ab808283b7242c))
* autocomplete positioning on first char in line ([7afb06c](https://github.com/Saghen/blink.cmp/commit/7afb06ca9962e3670b5ed01e7301709a53917edd))
* autocompletion window components alignment ([#51](https://github.com/Saghen/blink.cmp/issues/51)) ([a4f5f8e](https://github.com/Saghen/blink.cmp/commit/a4f5f8eef9182515050d94d54f4c2bb97767987b))
* binary symlink in flake only working on Linux ([#93](https://github.com/Saghen/blink.cmp/issues/93)) ([fc5feb8](https://github.com/Saghen/blink.cmp/commit/fc5feb887f3f379fff0756b2be2a35c8aa841a44))
* check if LSP supports resolve provider ([957a57a](https://github.com/Saghen/blink.cmp/commit/957a57a9d3d90c1a9974b9af66f4a9a1f80fdb5f)), closes [#48](https://github.com/Saghen/blink.cmp/issues/48)
* close completion if the accepted item matches the current word ([2f1b85b](https://github.com/Saghen/blink.cmp/commit/2f1b85bc4f15e2f3660550ef92161a93482f2fd8)), closes [#41](https://github.com/Saghen/blink.cmp/issues/41)
* close completion window on ctrl+c in insert mode ([#63](https://github.com/Saghen/blink.cmp/issues/63)) ([e695c79](https://github.com/Saghen/blink.cmp/commit/e695c798b2d53a429f2f3ba1551a21ae2c4dc11a))
* **config:** make blink lua config fields optional ([#18](https://github.com/Saghen/blink.cmp/issues/18)) ([9c73b0d](https://github.com/Saghen/blink.cmp/commit/9c73b0dc8c158c7162092258177ff8a03aa2919b))
* context not clearing on trigger character, path regexes ([15cb871](https://github.com/Saghen/blink.cmp/commit/15cb871d1f8c52050a0fcd07d31115f3a63cf20c)), closes [#16](https://github.com/Saghen/blink.cmp/issues/16)
* correctly handle non-blink keymaps with string rhs ([#78](https://github.com/Saghen/blink.cmp/issues/78)) ([1ad59aa](https://github.com/Saghen/blink.cmp/commit/1ad59aa6ab142c19508ee6ed222b73a3ffd13521))
* disable blink.cmp remaps when telescope prompt is open ([#104](https://github.com/Saghen/blink.cmp/issues/104)) ([7f2f74f](https://github.com/Saghen/blink.cmp/commit/7f2f74fe037ccad1a573e3d42f114d0d23b954d8)), closes [#102](https://github.com/Saghen/blink.cmp/issues/102)
* documentation manual trigger not updating on scroll ([cd15078](https://github.com/Saghen/blink.cmp/commit/cd15078763946522dddbb818803e99b2b321e742))
* documentation of snippet cannot be shown when description is list ([#92](https://github.com/Saghen/blink.cmp/issues/92)) ([f99bf6b](https://github.com/Saghen/blink.cmp/commit/f99bf6bdabadc2b47fd7355ae2af912a30b9c3cc))
* don't initialize first_fill with 1 ([#87](https://github.com/Saghen/blink.cmp/issues/87)) ([526f786](https://github.com/Saghen/blink.cmp/commit/526f786a8658f99dff36013b4e31d1f7e6b0a56b))
* double send on append on trigger character ([ebbce90](https://github.com/Saghen/blink.cmp/commit/ebbce90400ea1ed3e14fdec88fdef59c0185ad46)), closes [#25](https://github.com/Saghen/blink.cmp/issues/25)
* enable kind auto brackets for TS/JS ([808f628](https://github.com/Saghen/blink.cmp/commit/808f628713ae78665511be42b2c054c92208a00e))
* expand vars in snippets for insertText ([ce337cb](https://github.com/Saghen/blink.cmp/commit/ce337cb95f2172070c0e9333e3439eb20ae4c72a)), closes [#27](https://github.com/Saghen/blink.cmp/issues/27)
* **ffi:** handle cargo library naming conventions for windows binaries ([#74](https://github.com/Saghen/blink.cmp/issues/74)) ([e9493c6](https://github.com/Saghen/blink.cmp/commit/e9493c6aa4942da7e3a62c118195ea07df815dc2))
* guess text edit once and for all ([fc348da](https://github.com/Saghen/blink.cmp/commit/fc348dac16f190042d20aee62ea61b66c7c1380a))
* handle empty table in additionalTextEdits ([#99](https://github.com/Saghen/blink.cmp/issues/99)) ([65e9605](https://github.com/Saghen/blink.cmp/commit/65e9605924ff774fb3612441a1d18737b5c9f58a))
* handle newlines in autocomplete suggestions ([#110](https://github.com/Saghen/blink.cmp/issues/110)) ([c39227a](https://github.com/Saghen/blink.cmp/commit/c39227adfaf66939b6a319bb1ed43d9ade5bbd9b))
* passthrough bind on show/hide when shown/hidden ([a5145ae](https://github.com/Saghen/blink.cmp/commit/a5145ae69ef2d4193574a09fcd50bea20481f516)), closes [#49](https://github.com/Saghen/blink.cmp/issues/49)
* re-enable preselect by default ([64673ea](https://github.com/Saghen/blink.cmp/commit/64673ea454f46664ac6f6545f5d3577fd27421e9))
* replace keycodes on callback alternate mappings ([df5c0de](https://github.com/Saghen/blink.cmp/commit/df5c0de57b443545d4fe04cff9cd97ca3d20bbbf)), closes [#47](https://github.com/Saghen/blink.cmp/issues/47)
* respect autocomplete min_width ([#86](https://github.com/Saghen/blink.cmp/issues/86)) ([c15aefe](https://github.com/Saghen/blink.cmp/commit/c15aefeea77345b21ed79cb9defc322ae19f7eda))
* signature window failing when trigger context empty ([6a21d7c](https://github.com/Saghen/blink.cmp/commit/6a21d7c12d7186313e0dea2c04d0dd63b6534115))
* snippet keymaps not applying in insert ([a89ae20](https://github.com/Saghen/blink.cmp/commit/a89ae200840de7661eb92d8ae202b279ecc56da9)), closes [#70](https://github.com/Saghen/blink.cmp/issues/70)
* snippet source markdown generation ([a6cf72a](https://github.com/Saghen/blink.cmp/commit/a6cf72ae58362c126f91993326b5c8b43366eb7f))
* snippets source expanding vars ([5ffd608](https://github.com/Saghen/blink.cmp/commit/5ffd608dc4cd4df8fcfe43b366c5960f05056e45))
* strip blink fields from lsp items for resolve ([ab99b02](https://github.com/Saghen/blink.cmp/commit/ab99b02f4b5c378c7c79e5d24954d00450e78f1b))
* union_keys not using pairs ([8c2cb2e](https://github.com/Saghen/blink.cmp/commit/8c2cb2efb63411499f6746ae7be34e2b0a581bad))
* update ffi.lua ([27903be](https://github.com/Saghen/blink.cmp/commit/27903bef41bc745c4d5419e86ca5bf09ed538f2b))
* use correct prev/next keymap ([#53](https://github.com/Saghen/blink.cmp/issues/53)) ([f456c2a](https://github.com/Saghen/blink.cmp/commit/f456c2aa0994f709f9aec991ed2b4b705f787e48)), closes [/github.com/Saghen/blink.cmp/pull/23#issuecomment-2399876619](https://github.com/Saghen//github.com/Saghen/blink.cmp/pull/23/issues/issuecomment-2399876619)
* use empty separator for joining snippet description ([28f3a31](https://github.com/Saghen/blink.cmp/commit/28f3a316de01fc4a14c67689b0547428499e933d))
* use internal CompletionItemKind table ([4daf96d](https://github.com/Saghen/blink.cmp/commit/4daf96d76e06d6c248587f860ddb5717ced9bbd3)), closes [#17](https://github.com/Saghen/blink.cmp/issues/17)

## [0.2.1](https://github.com/Saghen/blink.cmp/compare/v0.2.0...v0.2.1) (2024-10-08)

### Features

* cycle completions ([#12](https://github.com/Saghen/blink.cmp/issues/12)) ([d20e34d](https://github.com/Saghen/blink.cmp/commit/d20e34d8c87925bd27dff12961588459f649cd92))

### Bug Fixes

* autocomplete window positioning with borders ([ba62bda](https://github.com/Saghen/blink.cmp/commit/ba62bda5af9b5f2a8accb102eb4791fab94e2a90)), closes [#29](https://github.com/Saghen/blink.cmp/issues/29)
* check server capabilities ([#5](https://github.com/Saghen/blink.cmp/issues/5)) ([8d2615d](https://github.com/Saghen/blink.cmp/commit/8d2615d00a9892647a6d0e0e564b781a4e6afabe))
* keymaps not replacing keycodes ([5dd7d66](https://github.com/Saghen/blink.cmp/commit/5dd7d667228e3a98d01146db7c4461f42644d0c1))
* keymaps replacing buffer local bindings ([506ea74](https://github.com/Saghen/blink.cmp/commit/506ea74e53a825cc6efd40a46c4129576409e440)), closes [#39](https://github.com/Saghen/blink.cmp/issues/39)
* use buffer-local keymaps ([ecb3510](https://github.com/Saghen/blink.cmp/commit/ecb3510ef2132956fb2df3dcc927e0f84d1a1c1d)), closes [#20](https://github.com/Saghen/blink.cmp/issues/20)
* use correct prev/next keymap for k and j ([#23](https://github.com/Saghen/blink.cmp/issues/23)) ([43e7532](https://github.com/Saghen/blink.cmp/commit/43e753228fe4a722e29d4953cad74a61728183cb))

## [0.2.0](https://github.com/Saghen/blink.cmp/compare/v0.1.0...v0.2.0) (2024-10-07)

### Features

* blink cmp specific winhighlights and highlights ([a034865](https://github.com/Saghen/blink.cmp/commit/a034865d585800503a61995a850ecb622a3d36cc))
* check for brackets in front of item ([2c6ee0d](https://github.com/Saghen/blink.cmp/commit/2c6ee0d5fa32e286255a4ca119ff74713676bf60))
* custom drawing support ([3e55028](https://github.com/Saghen/blink.cmp/commit/3e550286534e68cff42f96747e58db0610f7b4b5))
* customizable undo point ([876707f](https://github.com/Saghen/blink.cmp/commit/876707f214e7ca0875e05eae45b876396b6c33fb))
* introduce customizable winhighlight for autocomplete and documentation windows ([1a9cb7a](https://github.com/Saghen/blink.cmp/commit/1a9cb7ac70a912689ab09b96c6f9e75c888faed6))
* support keyword_length on sources ([77080a5](https://github.com/Saghen/blink.cmp/commit/77080a529f88064e0ff04ef69b08fbe7445bcd0d))

### Bug Fixes

* autocomplete window placement ([4e9d7ca](https://github.com/Saghen/blink.cmp/commit/4e9d7ca62c83c3ff2d64e925aab4dac10266f33b))
* frecency access scoring ([e736972](https://github.com/Saghen/blink.cmp/commit/e73697265ff9091c9cca3db060be60d8e3962c5e))
* misc ([5f4db7a](https://github.com/Saghen/blink.cmp/commit/5f4db7a1507dcca3b0f4d4fbeaef1f42262aea8f))
* path completions ([6a5cf05](https://github.com/Saghen/blink.cmp/commit/6a5cf05c704a42cfbfa3009d3ac8e727637567b8))
* respect min/max width for autocomplete window rendering ([0843884](https://github.com/Saghen/blink.cmp/commit/08438846b8016a9457c3234f4066655dc62b97a0))
* signature trigger config ([cf9e4aa](https://github.com/Saghen/blink.cmp/commit/cf9e4aaf778f56d2dda8f43c30cb68762aecc425))
* signature window showing up after context deleted ([857b336](https://github.com/Saghen/blink.cmp/commit/857b336ccdc5a389564e6e2b58571bc07c5cce32))
* window placement with border ([d6a81d3](https://github.com/Saghen/blink.cmp/commit/d6a81d320f8880e219a3f937ecea1f78aca680e3))

## [0.1.0](https://github.com/Saghen/blink.cmp/compare/1b282880e699be37c3719308d6660a68d9081b14...v0.1.0) (2024-10-05)

### Features

* .local/state db location and misc ([bf76a01](https://github.com/Saghen/blink.cmp/commit/bf76a01482f6a3f7e019d0050df73ccf8ad93cf6))
* accept and auto brackets config ([fd32689](https://github.com/Saghen/blink.cmp/commit/fd32689fbd07b953a54b61cc871f714c9dd004d5))
* add back to repo ([24422f2](https://github.com/Saghen/blink.cmp/commit/24422f2341acf6ebdf7c9bc798cd81fbf5029d03))
* add documentation keymaps ([e248579](https://github.com/Saghen/blink.cmp/commit/e248579b5cfe939048b613de7a7cdfcb884cd078))
* auto brackets support ([7203d51](https://github.com/Saghen/blink.cmp/commit/7203d5195970f300ee5529a8427060ee1db9ae41))
* basic snippet expansion and text edit support ([451dd9e](https://github.com/Saghen/blink.cmp/commit/451dd9eeaa37f6c5598bf7293b8da2bfdfe9162e))
* better documentation window positioning ([a7ee523](https://github.com/Saghen/blink.cmp/commit/a7ee523978ba653b6eb4d9bac2af1d70f6e89f7b))
* complete rework ([1efdc8a](https://github.com/Saghen/blink.cmp/commit/1efdc8a0ff38d3f1ff89acd9b04aa14844f50e42))
* consolidate context table ([ad9ba28](https://github.com/Saghen/blink.cmp/commit/ad9ba28d0a8c1fda91e24e33d29b8013dd4c760a))
* drop performance logging ([2974bc0](https://github.com/Saghen/blink.cmp/commit/2974bc0569b2d611ce399a733753c90f6ab61a9d))
* dynamic cmp and doc window width ([6b78c89](https://github.com/Saghen/blink.cmp/commit/6b78c89276f8a520b4b802c8893f30e0ee7a5c82))
* enable path source by default ([e7362c0](https://github.com/Saghen/blink.cmp/commit/e7362c0786ae889b738c9f1f34a312d834005d37))
* hack around LSPs returning filtered items ([b58a382](https://github.com/Saghen/blink.cmp/commit/b58a382640f2ddfe0b07ce70439e935e49e39e36))
* handle no items in source provider ([82106a4](https://github.com/Saghen/blink.cmp/commit/82106a482e899c27d3fa830aa7f65c020848fc68))
* immediate fuzzy on keystroke ([1d3d54f](https://github.com/Saghen/blink.cmp/commit/1d3d54f20f2412e33975db88a60c6f2c148e7903))
* implement snippets without deps ([37dbee4](https://github.com/Saghen/blink.cmp/commit/37dbee453dc2655a0a0e74d9b95ee00c08a8cf32))
* init flake ([87e0416](https://github.com/Saghen/blink.cmp/commit/87e041699169d4f837c5f430e26756f0c2f76623))
* initial ([1b28288](https://github.com/Saghen/blink.cmp/commit/1b282880e699be37c3719308d6660a68d9081b14))
* initial configuration support ([b101fc1](https://github.com/Saghen/blink.cmp/commit/b101fc117c4f161f78c1783391f8719c619d15a5))
* keymaps in config ([d6bad7b](https://github.com/Saghen/blink.cmp/commit/d6bad7bca485ffe6c254daf1e3d2df581b37eebc))
* lock position to context start ([6ee55d4](https://github.com/Saghen/blink.cmp/commit/6ee55d4e2d938b138246e6ab11adbb320b19f7e7))
* maintain window on immediate new context while deleting ([4d1b785](https://github.com/Saghen/blink.cmp/commit/4d1b7854c2d4c373cfdc027074aa305927c5414a))
* min score on fuzzy results, avoid trimming valid items ([14a014d](https://github.com/Saghen/blink.cmp/commit/14a014dce49e658f5eed32853c9241d7869bc5dd))
* misc ([e8372ab](https://github.com/Saghen/blink.cmp/commit/e8372abf86861a8fde4612257a4f9586626ad05f))
* multi-repo setup based on mini.nvim ([15e808b](https://github.com/Saghen/blink.cmp/commit/15e808b70704e5f909305c487cb7fbfd5a95fc46))
* nerd font variant and misc cleanup ([6571c96](https://github.com/Saghen/blink.cmp/commit/6571c96b3aede5ae4f37b3d4999a4ac374593910))
* nvim cmp as default highlight ([b93a5e3](https://github.com/Saghen/blink.cmp/commit/b93a5e3476b42fc8f79bdeb6fc0f5e0ca8b4bc68))
* pre-built binary download support, misc refactors ([b1004ab](https://github.com/Saghen/blink.cmp/commit/b1004ab8c23656a5cb3d20b67bc3e5485f818ade))
* put context via wrapper ([f5d4dae](https://github.com/Saghen/blink.cmp/commit/f5d4dae67c31c2239805187f6351a4dc99259e26))
* reenable auto_show for documentation ([f1f7de4](https://github.com/Saghen/blink.cmp/commit/f1f7de496fa653518dea34bfe0446d0babac7d4e))
* rework path source ([5787816](https://github.com/Saghen/blink.cmp/commit/5787816e5e28d1c61803552008545abc851505eb))
* rework sources again ([7568de9](https://github.com/Saghen/blink.cmp/commit/7568de938a49a26cebf39369e39211f1c959cd9c))
* rework sources system ([3ee91b5](https://github.com/Saghen/blink.cmp/commit/3ee91b50e7dfc0340b723ae06c4a06f9c8e1e437))
* show on insert on trigger character ([a9ff243](https://github.com/Saghen/blink.cmp/commit/a9ff243cf0271904708b8a6ef6bf3150238cbc2d))
* signature help and misc ([fbfdf29](https://github.com/Saghen/blink.cmp/commit/fbfdf2906ea145f4faaf94865eeb40bb30dd8db2))
* smarter caching, misc fixes ([3f1c8bd](https://github.com/Saghen/blink.cmp/commit/3f1c8bd81b9499345fa50e3707fa127a58160062))
* smarter fuzzy, drop logging ([6b09eaa](https://github.com/Saghen/blink.cmp/commit/6b09eaa8f47d9bba971a0fd1e8a9e93263bb69e1))
* sort _ items last ([210f21f](https://github.com/Saghen/blink.cmp/commit/210f21fe73c150253b3dd1529852522ee47b23d3))
* source should_show, windowing config/fixes, misc ([3d1c168](https://github.com/Saghen/blink.cmp/commit/3d1c1688c6888df50069d50b07e9641f53394ce0))
* update flake to reflect merge with mono-repo ([aa80347](https://github.com/Saghen/blink.cmp/commit/aa80347f93fb95df2ca98be2c03116a27c554e04))
* use naersk to simplify build, remove unused inputs ([5579688](https://github.com/Saghen/blink.cmp/commit/55796882a7354f9dbbea5997285e1cd4e92df905))
* use remote fzrs for build ([04d5647](https://github.com/Saghen/blink.cmp/commit/04d5647009d74e6c14050d094e9d66cd1ace0b5a))
* WIP sources rework ([ad347a1](https://github.com/Saghen/blink.cmp/commit/ad347a165d2f7e3030b0fe44261e4624d9826134))

### Bug Fixes

* a lot ([8a599ba](https://github.com/Saghen/blink.cmp/commit/8a599ba6725cc0892f6d0155fbbb4bd51a02c9d5))
* accept auto brackets ([3927e23](https://github.com/Saghen/blink.cmp/commit/3927e23926ef05fc729b065c771de6ee293a587f))
* add version to pkg ([8983597](https://github.com/Saghen/blink.cmp/commit/89835978d6f6d820abb398ed01a32fcb69a10232))
* avoid immediately showing on context change ([632e6ac](https://github.com/Saghen/blink.cmp/commit/632e6ac9f3ca7ad2f78fd5f5c100e9437fccf845))
* avoid setting filetype for preview for now ([32ef1b9](https://github.com/Saghen/blink.cmp/commit/32ef1b9e79a85e9cccee274171c07034ac1a3fc3))
* buffer response context ([4650a35](https://github.com/Saghen/blink.cmp/commit/4650a35d058aba78c8c59b0aad44f0a13a08a287))
* cancel signature help request on hide ([b1fdee5](https://github.com/Saghen/blink.cmp/commit/b1fdee5277aba73791a1c991a51df7ac940d4321))
* documentation delays ([01d5fd0](https://github.com/Saghen/blink.cmp/commit/01d5fd0fc3863e0cd2c9eb53739a369ed1ca4a4e))
* keymap and simplify ([0924c8a](https://github.com/Saghen/blink.cmp/commit/0924c8a9d64121677f4ed165d4fe65b3ccb8a3ff))
* keymaps ([863bad7](https://github.com/Saghen/blink.cmp/commit/863bad7d66d616b6498c7d9ba59249138517689a))
* lazy.nvim loading ([9115fc2](https://github.com/Saghen/blink.cmp/commit/9115fc2e1dfa64d9ed974d11bc3562e8fdf67449))
* maintain autocomplete pos when scrolling/resizing ([a720117](https://github.com/Saghen/blink.cmp/commit/a720117e49c47e9c45981b419427f5d636118338))
* plugin paths ([ae4aeae](https://github.com/Saghen/blink.cmp/commit/ae4aeae0a32fde09ce64b2bb9b056ef2f1f50ad2))
* proximity and frecency bonus ([7bb4000](https://github.com/Saghen/blink.cmp/commit/7bb40005fcfc713d04db1e33461170bc012344ed))
* reference correct signature window ([30855cd](https://github.com/Saghen/blink.cmp/commit/30855cde1e9b76c351133411fad15c0f13d1dcd8))
* remove debug prints ([013dc02](https://github.com/Saghen/blink.cmp/commit/013dc0276677741f7f8c1b436303355b975a0e73))
* remove references to removed inputs ([d69b4d1](https://github.com/Saghen/blink.cmp/commit/d69b4d1c6866455d443bb9ca9dac45b1235d0757))
* set pname instead of name ([addf204](https://github.com/Saghen/blink.cmp/commit/addf204b58014cd8a87b9af57e38406b896128ce))
* snippets items ([d8a593d](https://github.com/Saghen/blink.cmp/commit/d8a593db311d83e5d8cf8db0a5ada01e92e88b16))
* sources trigger character blocklist ([69d3854](https://github.com/Saghen/blink.cmp/commit/69d38546f166fff074d3e5458b0625653d7e2e91))
* trigger, docs, so much stuff ([fae11d1](https://github.com/Saghen/blink.cmp/commit/fae11d16bb4efac3b74f84040b1f50776e4d55cb))
* update package build dir to cmp/fuzzy ([13203e3](https://github.com/Saghen/blink.cmp/commit/13203e3cb0a9196635243d0b47c33a9cb7c1326c))
