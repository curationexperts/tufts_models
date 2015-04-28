module Publishable
  extend ActiveSupport::Concern

  STATE_DELETED = 'D'

  def publishable?
    true
  end

  def workflow_status
    raise "Production objects don't have a workflow" unless draft?
    if published?
      :published
    elsif published_at.blank?
      :new
    else
      :edited
    end
  end

  # Has this record been published yet?
  def published?
    published_at && published_at == edited_at
  end

  def draft?
    PidUtils.draft?(pid) || draft_namespace?
  end

  def find_draft
    self.class.find(PidUtils.to_draft(pid))
  end

  def find_published
    self.class.find(PidUtils.to_published(pid))
  end

  # copy the published object over the draft
  def revert!
    published_pid = PidUtils.to_published(pid)
    draft_pid = PidUtils.to_draft(pid)

    if self.class.exists? published_pid
      destroy_draft_version!
      FedoraObjectCopyService.new(self.class, from: published_pid, to: draft_pid).run
    end
  end

  private

  def destroy_draft_version!
    self.class.destroy_if_exists PidUtils.to_draft(pid)
  end

  def draft_namespace?
    inner_object && inner_object.respond_to?(:namespace) && inner_object.namespace == PidUtils.draft_namespace
  end

  module ClassMethods
    def build_draft_version(attrs = {})
      attrs.merge!(pid: PidUtils.to_draft(attrs[:pid])) if attrs[:pid]
      attrs.merge!(namespace: PidUtils.draft_namespace)
      new(attrs)
    end

    def destroy_if_exists(pid)
      if exists?(pid)
        find(pid).destroy
      end
    end
  end

end
