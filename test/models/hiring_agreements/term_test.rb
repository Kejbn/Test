require 'test_helper'

class HiringAgreements::TermTest < ActiveSupport::TestCase
  setup do
    @active_term = hiring_agreements_terms(:active)
  end

  test 'active terms' do
    assert HiringAgreements::Term.active?
    assert_equal @active_term, HiringAgreements::Term.active
  end

  test 'no active terms raises if queried' do
    @active_term.destroy

    assert_not HiringAgreements::Term.active?
    assert_raises ActiveRecord::RecordNotFound do
      HiringAgreements::Term.active
    end
  end

  test 'multiple active terms (invalid state) raises' do
    create_term!.update!(active: true)
    assert_raises ActiveRecord::SoleRecordExceeded do
      HiringAgreements::Term.active
    end
  end

  test 'activating a term deactivates all others' do
    new_term = create_term!
    new_term.activate!

    assert new_term.reload.active?
    assert_not @active_term.reload.active?
  end

  test "is signed by user when they've signed the most active terms" do
    user = users(:empty)
    assert_not HiringAgreements::Term.signed_by?(user)

    inactive_term = create_term!
    inactive_term.signatures.create!(user:)
    assert_not HiringAgreements::Term.signed_by?(user)

    @active_term.signatures.create!(user:)
    assert HiringAgreements::Term.signed_by?(user)
  end

  def create_term!(active: false)
    HiringAgreements::Term.create!(body: 'Body', active:)
  end
end
