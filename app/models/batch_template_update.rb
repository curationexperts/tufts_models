class BatchTemplateUpdate < Batch

  PRESERVE  = 'preserve'
  OVERWRITE = 'overwrite'

  def self.behavior_rules
    [PRESERVE, OVERWRITE]
  end

  validates :template_id, presence: true
  validates :pids,        presence: true
  validate  :template_not_empty
  validates :behavior, allow_blank: true,
        inclusion: { in: BatchTemplateUpdate.behavior_rules,
        message: "%{value} is not a valid template behavior" }


  def initialize(attrs={})
    pids = attrs.delete(:pids)
    pids ||= attrs.delete('pids')
    pids ||= []

    attrs['pids'] = pids.map { |pid| PidUtils.to_draft(pid) }.uniq
    super
  end

  def display_name
    "Update"
  end

  def overwrite?
    behavior == OVERWRITE
  end

  protected

    def template_not_empty
      if template_id? && TuftsTemplate.find(template_id).attributes_to_update.empty?
        errors.add(:base, "The selected template cannot be applied because it has no attributes filled out.")
      end
    end
end
