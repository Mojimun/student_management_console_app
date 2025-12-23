module Colorize
  def self.red(text); "\e[31m#{text}\e[0m"; end
  def self.green(text); "\e[32m#{text}\e[0m"; end
  def self.cyan(text); "\e[36m#{text}\e[0m"; end
  def self.gray(text); "\e[90m#{text}\e[0m"; end
end

class Student
  attr_accessor :name, :email, :id
  def initialize(id, name, email)
    @id, @name, @email = id, name, email
  end
end

class Course
  attr_accessor :title, :code, :id
  def initialize(id, title, code)
    @id, @title, @code = id, title, code
  end
end

class Enrollment
  attr_accessor :student_id, :course_id
  def initialize(s_id, c_id)
    @student_id, @course_id = s_id, c_id
  end
end

class AppManager
  attr_reader :students, :courses

  def initialize
    @students, @courses, @enrollments = [], [], []
    @next_student_id, @next_course_id = 1, 1
  end

  def add_student(name, email)
    student = Student.new(@next_student_id, name, email)
    @students << student
    @next_student_id += 1
    Colorize.green("Student: '#{name}' created (ID: #{student.id}).")
  end

  def add_course(title, code)
    course = Course.new(@next_course_id, title, code)
    @courses << course
    @next_course_id += 1
    Colorize.green("Course '#{title}' created (ID: #{course.id}).")
  end

  def list_students
    return Colorize.red("No students found.") if @students.empty?
    header = sprintf("%-5s | %-20s | %-30s", "ID", "Name", "Email")
    separator = Colorize.gray("-" * header.length)
    rows = @students.map { |s| sprintf("%-5s | %-20s | %-30s", s.id, s.name, s.email) }
    [Colorize.cyan(header), separator, rows].flatten.join("\n")
  end

  def list_courses
    return Colorize.red("No courses found.") if @courses.empty?
    header = sprintf("%-5s | %-25s | %-10s", "ID", "Title", "Code")
    separator = Colorize.gray("-" * header.length)
    rows = @courses.map { |c| sprintf("%-5s | %-25s | %-10s", c.id, c.title, c.code) }
    [Colorize.cyan(header), separator, rows].flatten.join("\n")
  end

  def enroll(student_id, course_id)
    student = @students.find { |s| s.id == student_id }
    course = @courses.find { |c| c.id == course_id }
    return Colorize.red("Error: Student or Course not found.") unless student && course
    if @enrollments.any? { |e| e.student_id == student_id && e.course_id == course_id }
      return Colorize.red("Error: Student already enrolled.")
    end
    @enrollments << Enrollment.new(student_id, course_id)
    Colorize.green("Enrolled #{student.name} in #{course.title}.")
  end

  def list_enrollments
    return Colorize.red("No enrollments.") if @enrollments.empty?
    header = sprintf("%-20s | %-20s", "Student", "Course")
    separator = Colorize.gray("-" * header.length)
    rows = @enrollments.map do |e|
      s = @students.find { |st| st.id == e.student_id }
      c = @courses.find { |co| co.id == e.course_id }
      sprintf("%-20s | %-20s", s.name, c.title)
    end
    [Colorize.cyan(header), separator, rows].flatten.join("\n")
  end

  def courses_for_student(s_id)
    student = @students.find { |s| s.id == s_id }
    return Colorize.red("Error: Student with ID #{s_id} not found.") unless student
    
    relevant_enrollments = @enrollments.select { |e| e.student_id == s_id }
    return Colorize.red("No courses found for #{student.name}.") if relevant_enrollments.empty?
    
    puts Colorize.cyan("\nCourses Enrolled by #{student.name}:")
    header = sprintf("%-10s | %-25s", "Code", "Course Title")
    separator = Colorize.gray("-" * header.length)
    rows = relevant_enrollments.map do |e|
      c = @courses.find { |co| co.id == e.course_id }
      sprintf("%-10s | %-25s", c.code, c.title)
    end
    [header, separator, rows].flatten.join("\n")
  end

  def students_in_course(c_id)
    course = @courses.find { |c| c.id == c_id }
    return Colorize.red("Error: Course with ID #{c_id} not found.") unless course
    
    relevant_enrollments = @enrollments.select { |e| e.course_id == c_id }
    return Colorize.red("No students enrolled in #{course.title}.") if relevant_enrollments.empty?
    
    puts Colorize.cyan("\nStudents Registered for #{course.title}:")
    header = sprintf("%-5s | %-20s", "ID", "Student Name")
    separator = Colorize.gray("-" * header.length)
    rows = relevant_enrollments.map do |e|
      s = @students.find { |st| st.id == e.student_id }
      sprintf("%-5s | %-20s", s.id, s.name)
    end
    [header, separator, rows].flatten.join("\n")
  end
end

def get_valid_input(prompt, regex, error_msg, options = {})
  loop do
    print prompt
    input = gets.chomp.strip
    
    input = input.split.map(&:capitalize).join(' ') if options[:capitalize]
    input = input.upcase if options[:upcase]
    input = input.downcase if options[:downcase]

    if options[:min] && input.length < options[:min]
      puts Colorize.red("Error: Minimum length is #{options[:min]} characters.")
      next
    end
    if options[:max] && input.length > options[:max]
      puts Colorize.red("Error: Maximum length is #{options[:max]} characters.")
      next
    end

    if input =~ regex
      if options[:unique_in] && options[:unique_in].any? { |item| item.send(options[:attr]) == input }
        puts Colorize.red("Error: This #{options[:attr]} already exists.")
        next
      end
      return input
    else
      puts Colorize.red(error_msg)
    end
  end
end

def run_app
  app = AppManager.new
  loop do
    puts "\n" + Colorize.cyan("--- Student-Course Management System ---")
    puts "1. Create Student\n2. List Students\n3. Create Course\n4. List Courses"
    puts "5. Enroll Student in Course\n6. List Enrollments\n7. Find Courses by Student\n8. Find Students by Course\n9. Exit"
    print "Enter choice: "
    choice = gets.chomp.to_i

    case choice
    when 1
      name = get_valid_input("Enter Name (3-20 chars): ", /\A[a-zA-Z\s]+\z/, "Invalid name! Only letters/spaces allowed.", {min: 3, max: 20, capitalize: true})
      email = get_valid_input("Enter Email: ", /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i, "Invalid email format!", {downcase: true, unique_in: app.students, attr: :email})
      puts app.add_student(name, email)
    when 2 then puts app.list_students
    when 3
      title = get_valid_input("Course Title (3-50 chars): ", /\A[a-zA-Z0-9\s]+\z/, "Invalid characters in title.", {min: 3, max: 50, capitalize: true})
      code = get_valid_input("Course Code (2-10 chars): ", /\A[a-zA-Z0-9]+\z/, "Code must be alphanumeric, no spaces.", {min: 2, max: 10, upcase: true, unique_in: app.courses, attr: :code})
      puts app.add_course(title, code)
    when 4 then puts app.list_courses
    when 5
      print "Student ID: "; s_id = gets.chomp.to_i
      print "Course ID: "; c_id = gets.chomp.to_i
      puts app.enroll(s_id, c_id)
    when 6 then puts app.list_enrollments
    when 7
      print "Student ID: "; s_id = gets.chomp.to_i
      puts app.courses_for_student(s_id)
    when 8
      print "Course ID: "; c_id = gets.chomp.to_i
      puts app.students_in_course(c_id)
    when 9 then puts Colorize.cyan("Goodbye!"); break
    else puts Colorize.red("Invalid Choice.")
    end
  end
end

run_app