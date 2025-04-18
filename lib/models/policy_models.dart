
class PolicyOption {
  final String id;
  final String title;
  final String description;
  final int cost;
  final String domain;

  PolicyOption({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.domain,
  });

  factory PolicyOption.fromJson(Map<String, dynamic> json) {
    return PolicyOption(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      cost: json['cost'],
      domain: json['domain'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cost': cost,
      'domain': domain,
    };
  }
}

class PolicyDomain {
  final String id;
  final String name;
  final String description;
  final List<PolicyOption> options;

  PolicyDomain({
    required this.id,
    required this.name,
    required this.description,
    required this.options,
  });

  factory PolicyDomain.fromJson(Map<String, dynamic> json) {
    return PolicyDomain(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      options: (json['options'] as List)
          .map((option) => PolicyOption.fromJson(option))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'options': options.map((option) => option.toJson()).toList(),
    };
  }
}