#==============================================================================
# RGSS3脚本
# 菜单增加读档
#==============================================================================

class Window_MenuCommand; alias m5_20151102_add_save_command add_save_command
  def add_save_command; m5_20151102_add_save_command
    add_command('读档', :m5_20151102_load); return unless @handler
    @handler[:m5_20151102_load] = ->{ SceneManager.call(Scene_Load) }
end; end

#==============================================================================
# RGSS3脚本
# 改造标题画面
#==============================================================================

class Window_TitleCommand
  def initialize
    super(0, 0)
    update_placement
    self.openness = 0
    self.opacity = 0
    open
  end
  def alignment
    return 1
  end
  #字体
  alias my_create_contents create_contents
  def create_contents
    my_create_contents
    contents.font.name = "AR CARTER"
    contents.font.bold = true
    contents.font.size = 60
  end
  #窗口位置
  def update_placement
    self.x = (Graphics.width - width) / 2
    self.y = (Graphics.height * 1.6 - height) / 2 - 20
  end
  #行高
  def line_height
    return 50
  end
#~   def item_width
#~     (width - standard_padding * 2 + spacing) / col_max - spacing
#~   end
#~   def window_width
#~     return 180
#~   end
  def make_command_list
    add_command("Start", :new_game)
    add_command("Continue", :continue, continue_enabled)
    add_command("Quit", :shutdown)
  end
end
