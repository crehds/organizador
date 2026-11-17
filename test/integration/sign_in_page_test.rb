require "test_helper"

# Guests land on the sign-in page at the root: the app's name on a centered card, like the entry to an intranet. In demo
# mode the card holds only the demo entry; a private installation shows only the form.
class SignInPageTest < ActionDispatch::IntegrationTest
  LINE = "Tareas con categoría, fecha de vencimiento y participantes, y notas que aparecen sin recargar la " \
         "página.".freeze

  test "in demo mode the sign-in page shows the notice, one line and the demo button, with no form" do
    [root_path, new_user_session_path].each do |path|
      get path

      assert_response :success
      assert_select ".demo-banner.alert-warning", count: 1
      assert_select ".demo-banner p", text: DEMO_NOTICE
      assert_select ".demo-banner form", count: 0
      assert_select "p.text-muted", count: 1
      assert_select "p.text-muted", text: LINE
      assert_select "form", count: 1
      assert_select "form[action=?][method=post] button", "/test", text: "Probar el demo"
      assert_select "input[name='user[email]'], input[name='user[password]']", count: 0
      assert_select ".entry h1", text: "Organizador"
      assert_select ".entry-card p.text-muted", text: LINE
      assert_select ".entry-card form[action=?] button", "/test"
      assert_select "h2, .badge", count: 0
      %w[Platzi Ruby Rails PostgreSQL Bootstrap Devise CanCanCan].each do |word|
        assert_not_includes response.body, word
      end
    end
  end

  test "outside demo mode the sign-in page is only the form, in Spanish" do
    with_demo_mode(false) do
      [root_path, new_user_session_path].each do |path|
        get path

        assert_response :success
        assert_select ".entry h1", text: "Organizador"
        assert_select ".entry-card h2", text: "Iniciar sesión"
        assert_select ".entry-card form[action=?]", user_session_path
        assert_select "form[action=?]", user_session_path, count: 1
        assert_select "form", count: 1
        assert_select "label[for=user_email]", text: /Correo/
        assert_select "label[for=user_password]", text: /Contraseña/
        assert_select "label[for=user_remember_me]", text: "Recordarme"
        assert_select "form[action=?] input[type=submit][value=Entrar]", user_session_path
        assert_select ".demo-banner, a[href='/test']", count: 0
        %w[Probar Platzi demo].each { |word| assert_not_includes response.body, word }
      end
    end
  end

  test "outside demo mode the Spanish form still signs the user in" do
    with_demo_mode(false) do
      post user_session_path, params: { user: { email: "outsider@tasker.com", password: "123456" } }

      assert_redirected_to root_path
      get tasks_path
      assert_response :success
    end
  end

  test "signed in users get their task list at the root" do
    task = create_task
    sign_in users(:juan)

    get root_path

    assert_response :success
    assert_select ".tasks.index-page"
    assert_includes response.body, task.name
  end

  test "the sign-in page at the root shows no user data and no signed-in chrome" do
    task = create_task(name: "Secreto de juan")

    [true, false].each do |demo|
      with_demo_mode(demo) { get root_path }

      assert_not_includes response.body, task.name
      User.pluck(:email).each { |email| assert_not_includes response.body, email }
      assert_select "nav.navbar", count: 0
    end
  end
end
