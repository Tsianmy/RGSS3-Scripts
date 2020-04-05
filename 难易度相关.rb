#==============================================================================
# ■ Difficulty
#------------------------------------------------------------------------------
=begin

简单的战斗难易度设置。

author    : Tsianmy
reference : Battle Difficulty - KGC_BattleDifficulty Ace

2020.4.5 Ver1.0

=end
#------------------------------------------------------------------------------
# 　★ - 新增  ☆ - 修改
#==============================================================================

module Difficulty
  #--------------------------------------------------------------------------
  # ● 常量
  #--------------------------------------------------------------------------
  VARIABLE = 5  #用于难易度设置的变量
  EASY = 1
  NORMAL = 0
  INITIAL_DIFFICULTY = EASY  #初始难度
  #--------------------------------------------------------------------------
  # ● 判定是否无视难易度
  #    判断敌人备注中有无 <无视难度>
  #--------------------------------------------------------------------------
  def self.ignore?(enemy)
    note = enemy.note
    note.split(/[\r\n]+/).each do |line|
      return true if line =~ /<无视难度>/
    end
    return false
  end
end

class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # ☆ 处理伤害
  #    调用前需要设置好
  #    @result.hp_damage   @result.mp_damage 
  #    @result.hp_drain    @result.mp_drain
  #--------------------------------------------------------------------------
  def execute_damage(user)
    on_damage(@result.hp_damage) if @result.hp_damage > 0
    #ADD--------->
    @result.hp_damage >>= 1 if $game_variables[Difficulty::VARIABLE] == Difficulty::EASY &&
        self.actor? && user.enemy? && !Difficulty.ignore?(user.enemy)
    #<---------
    self.hp -= @result.hp_damage
    self.mp -= @result.mp_damage
    user.hp += @result.hp_drain
    user.mp += @result.mp_drain
  end
end