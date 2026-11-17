require "test_helper"

# Shared categories, as a private installation keeps them; CategoryOwnershipTest covers demo mode.
class CategoriesTest < ActionDispatch::IntegrationTest
  setup do
    @previous_demo_mode = Rails.configuration.x.demo_mode
    Rails.configuration.x.demo_mode = false
    sign_in users(:johan)
  end

  teardown do
    Rails.configuration.x.demo_mode = @previous_demo_mode
  end

  test "lists categories" do
    get categories_path

    assert_response :success
    assert_includes response.body, categories(:desarrollo).name
  end

  test "creates a category" do
    assert_difference -> { Category.count } => 1 do
      post categories_path, params: { category: { name: "design", description: "UI work" } }
    end

    assert_redirected_to category_url(Category.find_by!(name: "design"))
  end

  test "rejects a duplicated category name" do
    assert_no_difference -> { Category.count } do
      post categories_path, params: { category: { name: "DESARROLLO", description: "--" } }
    end

    assert_response :unprocessable_entity
  end

  test "updates a category" do
    category = categories(:unused)

    patch category_path(category), params: { category: { name: "marketing" } }

    assert_redirected_to category_url(category)
    assert_equal "marketing", category.reload.name
  end

  test "deletes a category without tasks" do
    assert_difference -> { Category.count } => -1 do
      delete category_path(categories(:unused))
    end

    assert_redirected_to categories_url
  end

  test "keeps a category that still has tasks" do
    create_task

    assert_no_difference -> { Category.count } do
      delete category_path(categories(:desarrollo))
    end

    assert_redirected_to categories_url
    assert flash[:alert].present?
  end

  test "a JSON delete of a category with tasks answers 422" do
    create_task

    assert_no_difference -> { Category.count } do
      delete category_path(categories(:desarrollo), format: :json)
    end

    assert_response :unprocessable_entity
    assert response.parsed_body["base"].present?
  end
end
