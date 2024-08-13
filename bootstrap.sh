## Requirements ##
1. Takes the dotfile directory as an input(Can just assume pwd since it'll be run from the dotfile directory
2. Knows where to place each dotfile based on what it is(ie. nvim conifg file needs to go someplace other than .zshrc)
3. Updates to the dotfiles will be made in the git repo and automatically copied to the symlink



########### Install Stuff ############

# Install homebrew
# Install oh-my-zsh
# Install Vim-Plug

# brew install nvim
# brew install tmux
# brew install fzf
# brew install tree


########### Symlink Dotfiles ############


#### ZSH ####
ln -s -f ~/Dev/dotfiles/zsh/.zshrc ~/.zshrc



#### NVIM ####
# create ~/.config/nvim folder
mkdir ~/.config/nvim
ln -s ~/Dev/dotfiles/nvim/init.vim ~/.config/nvim/init.vim

# Install vim-plug plugins
# nvim
# :PlugInstall
# :UpdateRemotePlugins
# :q!
# :q!



#### Alacritty ####
#create ~/.config/alacritty/ folder
mkdir ~/.config/alacritty
ln -s ~/Dev/dotfiles/alacritty.yml ~/.config/alacritty/alacritty;yml

