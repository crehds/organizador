require "test_helper"

class CategoriesTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:johan)
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
end
