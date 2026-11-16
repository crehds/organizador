module ApplicationHelper
  # The email's first two letters on a circle colored from the email, so avatars need no external service.
  def avatar_for(user, size: 60)
    email = user.email
    tag.span(email.split("@").first.first(2).upcase,
             class: "user-avatar", role: "img", title: email, aria: { label: email },
             style: "--avatar-size: #{size}px; --avatar-hue: #{Zlib.crc32(email) % 360}")
  end
end
