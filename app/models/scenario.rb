class Scenario < ActiveRecord::Base
  include HasGuid

  belongs_to :user, counter_cache: :scenario_count, inverse_of: :scenarios
  has_many :scenario_memberships, dependent: :destroy, inverse_of: :scenario
  has_many :agents, through: :scenario_memberships, inverse_of: :scenarios

  validates_presence_of :name, :user

  validates_format_of :tag_fg_color, :tag_bg_color,
                      # Regex adapted from: http://stackoverflow.com/a/1636354/3130625
                      with: /\A#(?:[0-9a-fA-F]{3}){1,2}\z/, allow_nil: true,
                      message: "must be a valid hex color."

  validate :agents_are_owned

  def destroy_with_mode(mode)
    case mode
    when 'all_agents'
      Agent.destroy(agents.pluck(:id))
    when 'unique_agents'
      Agent.destroy(unique_agent_ids)
    end

    destroy
  end

  def self.icons
    @icons ||= YAML.load_file(Rails.root.join('config/icons.yml'))
  end

  private

  def unique_agent_ids
    agents.joins(:scenario_memberships)
      .group('scenario_memberships.agent_id')
      .having('count(scenario_memberships.agent_id) = 1')
      .pluck('scenario_memberships.agent_id')
  end

  def agents_are_owned
    unless agents.all? { |s| s.user == user }
      errors.add(:agents, 'must be owned by you')
    end

  validates_presence_of :schedule, in: Agent::SCHEDULES
    unless schedule.nil?
      if Agent::SCHEDULES.include?(schedule.to_s)
        true
      else
        errors.add(:schedule, "is not a valid schedule")
    end

  def validate_schedule
    Agent::SCHEDULES.include?(schedule.to_s)
  end
end
