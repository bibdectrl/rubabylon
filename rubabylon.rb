#!/usr/bin/env ruby

require 'gosu'

module Rubabylon

  class BabylonWindow < Gosu::Window
    attr_accessor :game, :selected, :wins
    def initialize
      super 640, 480, false
      self.caption = "Babylon"
      @game = Game.new self
      @red_block = Gosu::Image.new(self, "assets/red1.png", true)
      @green_block = Gosu::Image.new(self, "assets/green1.png", true)
      @blue_block = Gosu::Image.new(self, "assets/blue1.png", true)
      @brown_block = Gosu::Image.new(self, "assets/purple1.png", true)
      @game.stacks.each do |x|
        case x.col
        when :red
          x.pics.push @red_block
        when :green
          x.pics.push @green_block 
        when :blue
          x.pics.push @blue_block 
        when :brown
          x.pics.push @brown_block
        end
      end
      @bg = Gosu::Image.new(self, "assets/background.png", true)
      @game_font = Gosu::Font.new(self, "courier", 30)
      @title = Gosu::Image.new(self, "assets/title.png", true)
      @selected = nil
    end

    def new_game
      @game = Game.new self
      @game.stacks.each do |x|
        case x.col
        when :red
          x.pics.push @red_block
        when :green
          x.pics.push @green_block 
        when :blue
          x.pics.push @blue_block 
        when :brown
          x.pics.push @brown_block
        end
      end
    end

    def needs_cursor?
      true
    end

    def button_down id
      if id == Gosu::KbEscape then exit end
      if id == Gosu::MsLeft and @game.menu then @game.menu = false end
    end

    def selected?
      @selected != nil
    end

    def pick_up pile
      pile.select
      @selected = pile
    end

    def put_down pile
      unless @selected == pile
        @game.move @selected, pile
      end
      @selected.unselect
      pile.unselect
      @selected = nil
    end

    def update
      if @game.moves_left? and not @game.game_over
        if button_down? Gosu::MsLeft and not selected? then
          touching = find_stack mouse_x, mouse_y
          unless touching.nil?
            @selected = touching
            pick_up touching
          end
        end      
        if not button_down? Gosu::MsLeft and selected?
          touching = find_stack mouse_x, mouse_y
          unless touching.nil?
            put_down touching 
          else
            @game.stacks.each {|block| block.unselect}
            @selected = nil
          end
        end    
      elsif not @game.game_over
        @game.game_over = true
      end
      if @game.game_over
        if button_down? Gosu::MsLeft
          @game.game_over = false
          new_game
        end
      end
    end

    def find_stack(x, y)
      @game.stacks.each {|block| if mouse_x > block.x and mouse_x < block.x + 100 and mouse_y > block.y and mouse_y < block.y + 116 then return block end }
      return nil
    end
    
    def draw
      if @game.menu
        @title.draw(0, 0, 0)

      elsif not @game.game_over?
        @bg.draw(0, 0, 0)
        @game_font.draw("Current player: #{@game.current_player}", 310, 450, 0, 1.0, 1.0, Gosu::Color::BLACK)
        @game.stacks.each {|block| if not block.selected? then block.draw block.x, block.y, 0 else block.draw mouse_x - 50, mouse_y - 58, 1 end }
      else
        @bg.draw(0, 0, 0)
        @game_font.draw("Game over! Player #{@game.next_player} wins!", 80, 240, 0, 1.0, 1.0, Gosu::Color::BLACK) 
      end
    end
  end

  class Stack
    attr_accessor :col, :size, :pics, :selected, :x, :y
    def initialize(col,  pics = [], x = nil, y = nil, size = 1)
      @col = col
      @size = size
      @pics = pics
      @selected = false
      @x = x
      @y = y
    end

    def select
      @selected = true
    end

    def unselect
      @selected = false
    end

    def selected?
      @selected
    end

    def to_s
      "#{@col} #{@size}"
    end

    def can_stack other_stack
      self != other_stack && other_stack.col == self.col || other_stack.size == self.size
    end

    def stack_stacks other_stack
      Stack.new self.col, self.pics + other_stack.pics, x=other_stack.x, y=other_stack.y, self.size + other_stack.size
    end

    def draw x, y, z
      off = 0
      unless x.nil? or y.nil?
        pics.reverse.each do |pic|
          pic.draw x+off, y+off, z
          off += 3
        end
      end
    end
  end

  class Game
    attr_accessor :window, :stacks, :current_player, :next_player, :game_over, :menu
    @@starting_player = 1
    def initialize window
      @window = window
      @stacks = make_stacks
      @current_player = if @@starting_player == 1 then 1 else 2 end
      @next_player = if @current_player == 1 then 2 else 1 end
      @@starting_player = if @current_player == 2 then 1 else 2 end
      @menu = true
      @game_over = false
    end

    def make_stacks
      colours = [:red, :green, :blue, :brown]
      piles = [[80, 40], [204, 40], [328, 40], [452, 40],
               [80, 165], [204, 165], [328, 165], [452, 165],
               [80, 290], [204, 290], [328, 290], [452, 290]]
      stacks = []
      3.times do
        colours.each {|col| stacks.push Stack.new col }
      end
      stacks.shuffle.each {|stack| stack.x, stack.y = piles.pop}
    end

    def update_player
      if @current_player == 1 then @current_player = 2 else @current_player = 1 end
      if @next_player == 1 then @next_player = 2 else @next_player = 1 end
    end

    def move(s1, s2)
      if s1.can_stack s2
        new_stack = s1.stack_stacks s2
        @stacks.delete s1
        @stacks.delete s2
        @stacks.push new_stack
        update_player
        return true
      else
        return false
      end
    end

    def moves_left?
      @stacks.each do |s1|
        @stacks.each do |s2|
          unless s1 == s2
            if s2.can_stack s1 then return true end
          end
        end
      end
      false
    end

    def game_over?
      @game_over
    end
  end

end

Rubabylon::BabylonWindow.new.show
