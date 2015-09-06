class Player
  SIDES = [:backward, :left, :right, :forward]

  def play_turn(warrior)
    @binded_enemies_locations ||= []
    @w = warrior

    if need_rest?
      rest(warrior)
    elsif bomb
      handle_bomb(warrior)
    elsif free_enemy_near && free_enemy_near_count > 1
      bind_enemy! free_enemy_near
    elsif enemies_in_row
      warrior.detonate! enemies_in_row
    elsif free_enemy_near
      warrior.attack! free_enemy_near
    elsif binded_enemy_near
      attack_binded_enemy! binded_enemy_near
    elsif captive_near
      warrior.rescue! captive_near
    else
      walk(warrior)
    end
  end

  private

  def handle_bomb(warrior)
    bomb_side = warrior.direction_of(bomb)
    if bomb_near
      warrior.rescue! bomb_near
    elsif warrior.feel(bomb_side).empty?
      warrior.walk! bomb_side
    elsif warrior.feel(side_at_left(bomb_side)).enemy?
      bind_enemy! side_at_left(bomb_side)
    elsif warrior.feel(side_at_right(bomb_side)).enemy?
      bind_enemy! side_at_right(bomb_side)
    elsif warrior.feel(side_at_back(bomb_side)).enemy?
      bind_enemy! side_at_back(bomb_side)
    elsif enemies_in_row
      warrior.detonate! enemies_in_row
    elsif warrior.feel(bomb_side).enemy?
      warrior.attack! bomb_side
    end
  end

  def rest(warrior)
    if free_enemy_near
      bind_enemy! free_enemy_near
    else
      warrior.rest!
    end
  end

  def walk(warrior)
    if warrior.listen.any?
      walk_side = warrior.direction_of(warrior.listen.first)
      if warrior.feel(walk_side).stairs?
        if warrior.feel(side_at_left(walk_side)).empty?
          warrior.walk! side_at_left(walk_side)
        else
          warrior.walk! side_at_right(walk_side)
        end
      elsif location_empty?([location.first - 1, location.last - 1])
        warrior.walk! :backward
      elsif location_empty?([location.first - 1, location.last + 1])
        warrior.walk! :backward
      elsif location_empty?([location.first + 1, location.last - 1])
        warrior.walk! :left
      elsif location_empty?([location.first + 1, location.last + 1])
        warrior.walk! :right
      else
        warrior.walk! walk_side
      end
    else
      warrior.walk! warrior.direction_of_stairs
    end
  end

  def location_empty?(enemy_location)
    @w.listen.each do |space|
      if space.location.eql? enemy_location
        return true if space.enemy? || (@binded_enemies_locations.include? space.location)
      end
    end
    false
  end

  def bomb
    @w.listen.find(&:ticking?)
  end

  def bomb_near
    each_side { |side| return side if @w.feel(side).ticking? }
  end

  def side_at_left(side)
    { backward: :right, left: :backward, right: :forward, forward: :left }.fetch(side)
  end

  def side_at_right(side)
    { backward: :left, left: :forward, right: :backward, forward: :right }.fetch(side)
  end

  def side_at_back(side)
    { backward: :forward, left: :right, right: :left, forward: :backward }.fetch(side)
  end

  def need_rest?
    @need = true if @w.health <= 3
    @need = false if count_enemies == 0 || (count_enemies == 1 && @w.health >= 9) || @w.health >= 19
    @need
  end

  def count_enemies
    @w.listen.count(&:enemy?) + @binded_enemies_locations.size
  end

  def free_enemy_near
    each_side { |side| return side if @w.feel(side).enemy? }
  end

  def free_enemy_near_count
    count = 0
    each_side { |side| count += 1 if @w.feel(side).enemy? }
    count
  end

  def bind_enemy!(side)
    @w.bind!(side)
    @binded_enemies_locations.push @w.feel(side).location
  end

  def binded_enemy_near
    each_side { |side| return side if @w.feel(side).captive? && binded_enemy?(side) }
  end

  def captive_near
    each_side { |side| return side if @w.feel(side).captive? && !binded_enemy?(side) }
  end

  def binded_enemy?(side)
    @binded_enemies_locations.include? @w.feel(side).location
  end

  def attack_binded_enemy!(binded_enemy)
    @w.attack!(binded_enemy)
    @binded_enemies_locations.delete @w.feel(binded_enemy).location
  end

  def enemies_in_row
    each_side do |side|
      row = @w.look(side)
      return side if row[0].enemy? && row[1].enemy? && !row[2].captive?
    end
    nil
  end

  def each_side
    SIDES.each { |side| yield(side) }
    nil
  end

  def location
    [@w.feel.location.first - 1, @w.feel.location.last]
  end
end
