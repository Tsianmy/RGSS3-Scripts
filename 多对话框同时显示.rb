#==============================================================================
# ■ Ex
#------------------------------------------------------------------------------
# VX Script Author: J-SON
# VA Script Author: Tsianmy
# blog: https://lm-t.at.webry.info/200909/article_2.html
#
# ●功能
#   ◆设置子对话框
#   Ex.submessage( idx, msg, fname, fidx, bktype, msgpos )
#------------------------------------------------------------------------------
# 　★ - 新增  ☆ - 修改
#==============================================================================

module Ex
  #--------------------------------------------------------------------------
  # ● 常量
  #--------------------------------------------------------------------------
  #对话框背景
  MSGBK_NORMAL = 0  #普通
  MSGBK_DARK = 1    #暗色背景
  MSGBK_NONE = 2    #透明背景
  
  #对话框位置
  MSGPOS_TOP = 0     #上
  MSGPOS_CENTER = 1  #中
  MSGPOS_BOTTOM = 2  #下
  
  #--------------------------------------------------------------------------
  # ● 子消息设置
  #     index   : 子消息id(0 or 1)
  #     message : 子消息文章内容
  #     fname   : 脸图文件名
  #     findex  : 脸图id
  #     bktype  : 对话框背景类型(0, 1, 2)
  #     msgpos  : 对话框位置
  #--------------------------------------------------------------------------
  def self.submessage(
    index,
    message = [],
    fname = "",
    findex = 0,
    bktype = MSGBK_NORMAL,
    msgpos = MSGPOS_BOTTOM
  )
    return if index < 0 or index > 1
    submsg = $game_sub_messages[index]
    submsg.clear
    submsg.texts = message
    submsg.face_name = fname
    submsg.face_index = findex
    submsg.background = bktype
    submsg.position = msgpos
  end
end

#==============================================================================
# ■ Window_Message
#------------------------------------------------------------------------------
# 　显示文字信息的窗口。
#==============================================================================

class Window_Message < Window_Base
  #--------------------------------------------------------------------------
  # ☆ 初始化对象
  #--------------------------------------------------------------------------
  def initialize(game_message = nil, main_window = true)
    super(0, 0, window_width, window_height)
    self.z = 200
    self.openness = 0
    create_all_windows
    create_back_bitmap
    create_back_sprite
    clear_instance_variables
    
    # ADD --------->
    @game_message = (game_message == nil ? $game_message : game_message)
    @main_window = main_window
    
    @sub_windows = [ nil, nil ]
    if @main_window == true
      @sub_windows[0] = Window_Message.new($game_sub_messages[0], false)
      @sub_windows[1] = Window_Message.new($game_sub_messages[1], false)
    end
    #<--------------
    
  end
  #--------------------------------------------------------------------------
  # ☆ 更新画面
  #--------------------------------------------------------------------------
  def update
    super
    update_all_windows
    # ADD --------->
    update_sub_windows
    #<--------------
    update_back_sprite
    update_fiber
  end
  #--------------------------------------------------------------------------
  # ★ 更新子窗口
  #--------------------------------------------------------------------------
  def update_sub_windows
    if @main_window == true
      for i in 0..1
        @sub_windows[i].update
      end
    end
  end
  #--------------------------------------------------------------------------
  # ☆ 更新纤程
  #--------------------------------------------------------------------------
  def update_fiber
    if @fiber
      @fiber.resume
    elsif @game_message.busy? && !@game_message.scroll_mode
      @fiber = Fiber.new { fiber_main }
      @fiber.resume
    else
      @game_message.visible = false
    end
  end
  #--------------------------------------------------------------------------
  # ☆ 处理纤程的主逻辑
  #--------------------------------------------------------------------------
  def fiber_main
    @game_message.visible = true
    update_background
    update_placement
    loop do
      process_all_text if @game_message.has_text?
      process_input
      @game_message.clear
      @gold_window.close
      Fiber.yield
      break unless text_continue?
    end
    close_and_wait
    @game_message.visible = false
    @fiber = nil
  end
  #--------------------------------------------------------------------------
  # ☆ 更新窗口背景
  #--------------------------------------------------------------------------
  def update_background
    @background = @game_message.background
    self.opacity = @background == 0 ? 255 : 0
  end
  #--------------------------------------------------------------------------
  # ☆ 更新窗口的位置
  #--------------------------------------------------------------------------
  def update_placement
    @position = @game_message.position
    self.y = @position * (Graphics.height - height) / 2
    @gold_window.y = y > 0 ? 0 : Graphics.height - @gold_window.height
  end
  #--------------------------------------------------------------------------
  # ☆ 处理所有内容
  #--------------------------------------------------------------------------
  def process_all_text
    open_and_wait
    text = convert_escape_characters(@game_message.all_text).clone
    pos = {}
    new_page(text, pos)
    process_character(text.slice!(0, 1), text, pos) until text.empty?
  end
  #--------------------------------------------------------------------------
  # ☆ 输入处理
  #--------------------------------------------------------------------------
  def process_input
    if @game_message.choice?
      input_choice
    elsif @game_message.num_input?
      input_number
    elsif @game_message.item_choice?
      input_item
    else
      input_pause unless @pause_skip
    end
  end
  #--------------------------------------------------------------------------
  # ☆ 判定文字是否继续显示
  #--------------------------------------------------------------------------
  def text_continue?
    @game_message.has_text? && !settings_changed?
  end
  #--------------------------------------------------------------------------
  # ☆ 判定背景和位置是否被更改
  #--------------------------------------------------------------------------
  def settings_changed?
    @background != @game_message.background ||
    @position != @game_message.position
  end
  #--------------------------------------------------------------------------
  # ☆ 翻页处理
  #--------------------------------------------------------------------------
  def new_page(text, pos)
    contents.clear
    draw_face(@game_message.face_name, @game_message.face_index, 0, 0)
    reset_font_settings
    pos[:x] = new_line_x
    pos[:y] = 0
    pos[:new_x] = new_line_x
    pos[:height] = calc_line_height(text)
    clear_flags
  end
  #--------------------------------------------------------------------------
  # ☆ 获取换行位置
  #--------------------------------------------------------------------------
  def new_line_x
    @game_message.face_name.empty? ? 0 : 112
  end
  #--------------------------------------------------------------------------
  # ☆ 处理输入等待
  #--------------------------------------------------------------------------
  def input_pause
    self.pause = true
    wait(10)
    if @main_window == true
      Fiber.yield until Input.trigger?(:B) || Input.trigger?(:C)
      Input.update
      finish_pause
    else
      Fiber.yield while self.pause
    end
  end
  #--------------------------------------------------------------------------
  # ★ 等待结束
  #--------------------------------------------------------------------------
  def finish_pause
    self.pause = false
    if @main_window == true
      for i in 0..1
        @sub_windows[i].finish_pause
      end
    end
  end
end

#==============================================================================
# ■ Game_Message
#------------------------------------------------------------------------------
# 　处理信息窗口状态、文字显示、选项等的类。本类的实例请参考 $game_message 。
#==============================================================================
class Game_Message
  #--------------------------------------------------------------------------
  # ★ 定义实例变量
  #--------------------------------------------------------------------------
  attr_accessor   :texts                  # 文字数组（行单位）
end

#==============================================================================
# ■ DataManager
#------------------------------------------------------------------------------
# 　数据库和游戏实例的管理器。所有在游戏中使用的全局变量都在这里初始化。
#==============================================================================
module DataManager
  #--------------------------------------------------------------------------
  # ☆ 生成各种游戏对象
  #--------------------------------------------------------------------------
  def self.create_game_objects
    $game_temp          = Game_Temp.new
    $game_system        = Game_System.new
    $game_timer         = Game_Timer.new
    $game_message       = Game_Message.new
    # ADD -------------->
    $game_sub_messages  = [ Game_Message.new, Game_Message.new ]
    #<--------------
    $game_switches      = Game_Switches.new
    $game_variables     = Game_Variables.new
    $game_self_switches = Game_SelfSwitches.new
    $game_actors        = Game_Actors.new
    $game_party         = Game_Party.new
    $game_troop         = Game_Troop.new
    $game_map           = Game_Map.new
    $game_player        = Game_Player.new
  end
end

#==============================================================================
# ■ Scene_Map
#------------------------------------------------------------------------------
# 　地图画面
#==============================================================================
class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # ☆ 生成信息窗口
  #--------------------------------------------------------------------------
  def create_message_window
    @message_window = Window_Message.new($game_message, true)
  end
end