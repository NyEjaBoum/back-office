package model;

public class Employe {
    private String name;
    private int age;
    private String[] skills;

    public Employe() {
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    public String[] getSkills() {
        return skills;
    }

    public void setSkills(String[] skills) {
        this.skills = skills;
    }

    @Override
    public String toString() {
        return "Employe{name='" + name + "', age=" + age + ", skills=" + java.util.Arrays.toString(skills) + "}";
    }
}
