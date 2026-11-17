# "Probar el demo": first deletes visitor accounts older than LIFETIME with all their data, then creates a visitor
# with a random email and password, never shown, and its own copy of the sample categories and tasks.
# Outside demo mode it refuses before touching anything, because a private installation holds real data.
class DemoSandbox
  class Disabled < StandardError; end
  class Unavailable < StandardError; end

  LIFETIME = 24.hours

  CATEGORIES = %w[desarrollo mercadeo conceptualización ejercicios].freeze

  # [category, description] of each sample task. Juan is responsible, Leon follows, and Andrea gets a random role.
  TASKS = [
    ["conceptualización", "Bienvenida "],
    ["conceptualización", "¿Qué es ruby on rails y por qué usarlo?"],
    ["conceptualización", "Entorno de desarrollo de RoR"],
    ["ejercicios", "Instalación de Ruby, RoR en windows y Linux"],
    ["conceptualización", "Entender la web con rieles"],
    ["ejercicios", "Crear una nueva aplicación RoR ¡Hola Rails!"],
    ["ejercicios", "Manipular el patrón MVC"],
    ["conceptualización", "¿Qué vamos a desarrollar?"],
    ["desarrollo", "Crear la base de nuestra aplicación"],
    ["desarrollo", "Los secretos de rails"],
    ["conceptualización", "Assets y Layouts"],
    ["conceptualización", "Diseñar el modelo de datos"],
    ["desarrollo", "Agregar primer conjunto de scaffolds"],
    ["desarrollo", "Cómo entender las migraciones"],
    ["desarrollo", "Esteroides para tu desarrollo - HAML"],
    ["desarrollo", "Esteroides para tu desarrollo - Simple Form"],
    ["desarrollo", "Regenerando el primer conjunto de scaffolds"],
    ["desarrollo", "Internacionalización de tu aplicación"],
    ["conceptualización", "Esteroides para tu desarrollo - Debugging"],
    ["desarrollo", "Agregar validaciones de modelo"],
    ["desarrollo", "Añadiendo el concepto de usuario"],
    ["desarrollo", "Añadir participantes a la tarea"],
    ["desarrollo", "CanCanCan ¿puedes hacerlo?"],
    ["desarrollo", "Callbacks en Rails"],
    ["desarrollo", "Enviar email a los participantes"],
    ["desarrollo", "Añadir comentarios vía AJAX"],
    ["desarrollo", "Embellecer nuestra aplicación"],
    ["conceptualización", "Desplegando a Heroku"],
    ["conceptualización", "Conclusiones"]
  ].freeze

  def self.call
    unless Rails.configuration.x.demo_mode
      raise Disabled, "Demo mode is off (DEMO_MODE is not \"true\"), so no visitor was deleted or created."
    end

    delete_expired_visitors
    create_visitor
  end

  def self.delete_expired_visitors
    expired = User.visitors.where(created_at: ...LIFETIME.ago).select(:id)
    tasks = Task.where(owner_id: expired).select(:id)

    ActiveRecord::Base.transaction do
      # Children before parents, so every delete respects the foreign keys.
      Note.where(task_id: tasks).or(Note.where(user_id: expired)).delete_all
      Participant.where(task_id: tasks).or(Participant.where(user_id: expired)).delete_all
      Task.where(owner_id: expired).delete_all
      Category.where(user_id: expired).delete_all
      User.where(id: expired).delete_all
    end
  end
  private_class_method :delete_expired_visitors

  def self.create_visitor
    teammates = User.teammates.index_by { |user| user.email.split("@").first }
    if teammates.size < User::TEAMMATE_EMAILS.size
      raise Unavailable, "The teammates are missing; run bin/rails demo:reset."
    end

    ActiveRecord::Base.transaction do
      visitor = User.create!(email: "visitante-#{SecureRandom.hex(8)}@#{User::VISITOR_DOMAIN}",
                             password: SecureRandom.base58(32))
      copy_sample_data(visitor, teammates)
      visitor
    end
  end
  private_class_method :create_visitor

  def self.copy_sample_data(visitor, teammates)
    categories = CATEGORIES.index_with { |name| visitor.categories.create!(name:, description: "--") }

    TASKS.each.with_index(1) do |(category, description), number|
      Task.create!(
        name: "Tarea ##{number}", description:, due_date: Time.zone.today + 15.days, owner: visitor,
        category: categories.fetch(category),
        participating_users: [
          Participant.new(user: teammates.fetch("juan"), role: :responsable),
          Participant.new(user: teammates.fetch("leon"), role: :follower),
          Participant.new(user: teammates.fetch("andrea"), role: Participant.roles.keys.sample)
        ]
      )
    end
  end
  private_class_method :copy_sample_data
end
