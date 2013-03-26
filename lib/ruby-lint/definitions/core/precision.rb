##
# Constant: Precision
# Created:  2013-03-26 22:45:01 +0100
# Platform: rubinius 2.0.0.rc1 (1.9.3 cbee9a2d yyyy-mm-dd JI) [x86_64-unknown-linux-gnu]
#
RubyLint.global_scope.define_constant('Precision') do |klass|

  klass.define_method('__module_init__')

  klass.define_method('included') do |method|
    method.define_argument('klass')
  end

  klass.define_instance_method('prec') do |method|
    method.define_argument('klass')
  end

  klass.define_instance_method('prec_f')

  klass.define_instance_method('prec_i')
end
