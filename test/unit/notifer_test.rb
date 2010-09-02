require 'test_helper'

class NotiferTest < ActionMailer::TestCase
  test "form_submission" do
    @expected.subject = 'Notifer#form_submission'
    @expected.body    = read_fixture('form_submission')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Notifer.create_form_submission(@expected.date).encoded
  end

end
